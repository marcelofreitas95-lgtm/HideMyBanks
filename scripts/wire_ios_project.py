"""Add native sources/monitor to the generated Flutter Xcode project, once."""
from pathlib import Path
import hashlib
import re
import plistlib

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "ios/Runner.xcodeproj/project.pbxproj"

def ident(name):
    return hashlib.sha256(("calculadora:" + name).encode()).hexdigest()[:24].upper()

def wire():
    text = PROJECT.read_text(encoding="utf-8")
    if "/* ProtectionPlugin.swift in Sources */" in text:
        print("Native targets already wired.")
        return
    additions = {}
    def add(section, body):
        additions.setdefault(section, []).append(body)
    def file(name, path, kind):
        key = ident(name)
        add("PBXFileReference", f'\t\t{key} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {kind}; path = "{path}"; sourceTree = SOURCE_ROOT; }};')
        return key
    def build(name, ref, suffix="Sources"):
        key = ident(name + suffix)
        add("PBXBuildFile", f'\t\t{key} /* {name} in {suffix} */ = {{isa = PBXBuildFile; fileRef = {ref}; }};')
        return key
    files = {name: file(name, path, kind) for name, path, kind in [
        ("ProtectionPlugin.swift", "Runner/ProtectionPlugin.swift", "sourcecode.swift"),
        ("CodeVault.swift", "Runner/CodeVault.swift", "sourcecode.swift"),
        ("ProtectionPolicy.swift", "Shared/ProtectionPolicy.swift", "sourcecode.swift"),
        ("MonitorExtension.swift", "DeviceActivityMonitor/MonitorExtension.swift", "sourcecode.swift"),
        ("Runner.entitlements", "Runner/Runner.entitlements", "text.plist.entitlements"),
        ("Monitor.entitlements", "DeviceActivityMonitor/Monitor.entitlements", "text.plist.entitlements"),
        ("MonitorInfo.plist", "DeviceActivityMonitor/Info.plist", "text.plist.xml"),
        ("PrivacyInfo.xcprivacy", "Runner/PrivacyInfo.xcprivacy", "text.xml"),
    ]}
    app_sources = [build(name, files[name]) for name in
                   ("ProtectionPlugin.swift", "CodeVault.swift", "ProtectionPolicy.swift")]
    monitor_sources = [build(name + "Monitor", files[name]) for name in
                       ("MonitorExtension.swift", "ProtectionPolicy.swift")]
    privacy = build("PrivacyInfo.xcprivacy", files["PrivacyInfo.xcprivacy"], "Resources")
    product = ident("Monitor.appex")
    add("PBXFileReference", f'\t\t{product} /* Monitor.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; path = Monitor.appex; sourceTree = BUILT_PRODUCTS_DIR; }};')
    embed = ident("embedMonitor")
    add("PBXBuildFile", f'\t\t{embed} /* Monitor.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = {product}; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};')
    target, sources, frameworks, resources, embed_phase = [ident(x) for x in
        ("monitorTarget", "monitorSources", "monitorFrameworks", "monitorResources", "embedPhase")]
    add("PBXCopyFilesBuildPhase", f'\t\t{embed_phase} = {{isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = ({embed}, ); name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0; }};')
    add("PBXSourcesBuildPhase", f'\t\t{sources} = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(monitor_sources)}, ); runOnlyForDeploymentPostprocessing = 0; }};')
    add("PBXFrameworksBuildPhase", f'\t\t{frameworks} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};')
    add("PBXResourcesBuildPhase", f'\t\t{resources} = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};')
    proxy, dependency, configs = ident("monitorProxy"), ident("monitorDependency"), ident("monitorConfigs")
    add("PBXContainerItemProxy", f'\t\t{proxy} = {{isa = PBXContainerItemProxy; containerPortal = 97C146E61CF9000F007C117D; proxyType = 1; remoteGlobalIDString = {target}; remoteInfo = Monitor; }};')
    add("PBXTargetDependency", f'\t\t{dependency} = {{isa = PBXTargetDependency; target = {target}; targetProxy = {proxy}; }};')
    add("PBXNativeTarget", f'\t\t{target} /* Monitor */ = {{isa = PBXNativeTarget; buildConfigurationList = {configs}; buildPhases = ({sources}, {frameworks}, {resources}, ); buildRules = (); dependencies = (); name = Monitor; productName = Monitor; productReference = {product}; productType = "com.apple.product-type.app-extension"; }};')
    config_ids = []
    for name in ("Debug", "Release", "Profile"):
        key = ident("monitor" + name)
        config_ids.append(key)
        settings = {
            "APPLICATION_EXTENSION_API_ONLY": "YES", "CLANG_ENABLE_MODULES": "YES",
            "CODE_SIGN_ENTITLEMENTS": '"DeviceActivityMonitor/Monitor.entitlements"',
            "CODE_SIGN_STYLE": "Automatic", "CURRENT_PROJECT_VERSION": "1",
            "INFOPLIST_FILE": '"DeviceActivityMonitor/Info.plist"',
            "IPHONEOS_DEPLOYMENT_TARGET": "16.0", "MARKETING_VERSION": "1.0.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.calculadora.calculadora.Monitor",
            "PRODUCT_NAME": '"$(TARGET_NAME)"', "SDKROOT": "iphoneos",
            "SKIP_INSTALL": "YES", "SWIFT_VERSION": "5.0", "TARGETED_DEVICE_FAMILY": "1",
            "LD_RUNPATH_SEARCH_PATHS": '("$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks", )',
        }
        if name == "Debug":
            settings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"
            settings["SWIFT_OPTIMIZATION_LEVEL"] = '"-Onone"'
        body = " ".join(f"{k} = {v};" for k, v in settings.items())
        add("XCBuildConfiguration", f'\t\t{key} = {{isa = XCBuildConfiguration; buildSettings = {{{body}}}; name = {name}; }};')
    add("XCConfigurationList", f'\t\t{configs} = {{isa = XCConfigurationList; buildConfigurations = ({", ".join(config_ids)}, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};')
    group = ident("nativeGroup")
    add("PBXGroup", f'\t\t{group} /* Native Protection */ = {{isa = PBXGroup; children = ({", ".join(files.values())}, ); name = "Native Protection"; sourceTree = "<group>"; }};')
    for section, entries in additions.items():
        marker = f"/* End {section} section */"
        assert marker in text, section
        text = text.replace(marker, "\n".join(entries) + "\n" + marker)
    def add_to_list(object_id, field, entries, prepend=False):
        nonlocal text
        pattern = r"(" + object_id + r"\b[^=]*=\s*\{.*?\b" + field + r" = \()(.*?)(\);)"
        additions_text = "\n".join("\t\t\t\t" + e + "," for e in entries)
        def insert(match):
            content = ("\n" + additions_text + match[2] if prepend else
                       match[2] + "\n" + additions_text + "\n\t\t\t")
            return match[1] + content + match[3]
        text, count = re.subn(pattern, insert, text, count=1, flags=re.S)
        assert count == 1, (object_id, field)
    add_to_list("97C146EA1CF9000F007C117D", "files", app_sources)
    add_to_list("97C146EC1CF9000F007C117D", "files", [privacy])
    # Flutter requires embedding extensions before its Run Script build phase.
    add_to_list("97C146ED1CF9000F007C117D", "buildPhases", [embed_phase], prepend=True)
    add_to_list("97C146ED1CF9000F007C117D", "dependencies", [dependency])
    add_to_list("97C146E61CF9000F007C117D", "targets", [target])
    add_to_list("97C146E51CF9000F007C117D", "children", [group])
    add_to_list("97C146EF1CF9000F007C117D", "children", [product])
    text = text.replace("IPHONEOS_DEPLOYMENT_TARGET = 13.0;", "IPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    text = text.replace('TARGETED_DEVICE_FAMILY = "1,2";', 'TARGETED_DEVICE_FAMILY = 1;')
    text = text.replace("INFOPLIST_FILE = Runner/Info.plist;",
        'INFOPLIST_FILE = Runner/Info.plist;\n\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n\t\t\t\tCODE_SIGN_STYLE = Automatic;')
    PROJECT.write_text(text, encoding="utf-8")
    info = ROOT / "ios/Runner/Info.plist"
    data = plistlib.loads(info.read_bytes())
    data["CalculatorAppGroup"] = "group.com.calculadora.calculadora"
    data["ITSAppUsesNonExemptEncryption"] = False
    info.write_bytes(plistlib.dumps(data, sort_keys=False))
    print("Native app and monitor extension wired.")

if __name__ == "__main__": wire()
