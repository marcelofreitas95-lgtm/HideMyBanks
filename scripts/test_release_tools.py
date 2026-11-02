import json
from pathlib import Path
import tempfile
import unittest
from prepare_pal_source import make_source, stage
from release_gate import REQUIRED, validate
from configure_ios import configure

class ReleaseTests(unittest.TestCase):
    def identity(self):
        return dict(bundleIdentifier='com.testing.calculadora', teamID='TEST123456',
                    marketplaceID='123456789', developerName='Test Developer',
                    website='https://testing.test', privacyURL='https://testing.test/privacy',
                    iconURL='https://testing.test/icon.png', screenshots=['https://testing.test/screen.png'],
                    version='1.0.0', buildNumber=1)
    def signing(self):
        return dict(bundleIdentifier='com.testing.calculadora', version='1.0.0', buildNumber=1,
                    signatureVerified=True, monitorVerified=True,
                    profileType='app_store',
                    entitlements=['com.apple.developer.family-controls','com.apple.security.application-groups'])
    def readiness(self):
        return {'version':'1.0.0','buildNumber':1} | {
            key: {'passed': True, 'evidence':'unit-test fixture'} for key in REQUIRED}
    def test_empty_evidence_blocks_release(self):
        data=self.readiness(); data['notificationsSuppressed']['evidence']=''
        self.assertTrue(validate(self.identity(),data))
    def test_other_build_is_rejected(self):
        data=self.readiness(); data['buildNumber']=2
        self.assertTrue(validate(self.identity(),data))
    def test_complete_fixture_is_accepted(self):
        self.assertEqual(validate(self.identity(),self.readiness()),[])
    def test_pal_source_points_to_adp_manifest(self):
        source=make_source(self.identity(),'https://testing.test/adp/manifest.json',42,self.signing()['entitlements'])
        app=source['apps'][0]
        self.assertEqual(app['marketplaceID'],'123456789')
        self.assertTrue(app['versions'][0]['downloadURL'].endswith('/manifest.json'))
        self.assertEqual(app['appPermissions']['entitlements'],self.signing()['entitlements'])
    def test_adp_copy_preserves_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory); adp=root/'adp'; adp.mkdir()
            contents={'manifest.json':b'{ "unchanged" : true }\n','signature':b'signed-bytes',
                      'variant/test.ipa':b'unit-test-placeholder'}
            for name,data in contents.items():
                file=adp/name; file.parent.mkdir(parents=True,exist_ok=True); file.write_bytes(data)
            target=root/'publication'
            stage(adp,target,self.identity(),'https://testing.test',self.signing())
            for name,data in contents.items():
                self.assertEqual((target/'adp/1.0.0-1'/name).read_bytes(),data)
            self.assertEqual(len(json.loads((target/'integrity.json').read_text())),3)
            with self.assertRaises(ValueError): stage(adp,target,self.identity(),'https://testing.test',self.signing())
    def test_unsigned_or_other_version_report_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            signing=self.signing(); signing['signatureVerified']=False
            with self.assertRaises(ValueError): stage(Path(directory)/'adp',Path(directory)/'pub',self.identity(),'https://testing.test',signing)
    def test_placeholder_identifier_is_rejected_before_mutation(self):
        with self.assertRaises(ValueError): configure('com.calculadora.calculadora','TEST123456','1.0.0',1)

if __name__ == '__main__': unittest.main()
