#!/usr/bin/env ruby

require 'yaml'

def inline_cert(cert)
  IO.readlines(cert).map(&:strip).reject(&:empty?)[1 ... -1].join
end

if ARGV.size < 5
  puts "Usage: metadata-sources.rb rp_signing rp_encryption msa_signing msa_encryption output_dir"
  exit 1
end

rp_signing_cert = ARGV[0]
rp_encryption_cert = ARGV[1]
msa_signing_cert = ARGV[2]
msa_encryption_cert = ARGV[3]
output_dir = ARGV[4]

idps = ['stub-idp-one', 'stub-idp-two', 'stub-idp-three', 'stub-idp-four']
rps = ['dev-rp']

Dir::mkdir(output_dir) unless Dir::exist?(output_dir)

Dir::chdir(output_dir) do
  ['idps', 'matching-services', 'transactions'].each do |dir|
    Dir::mkdir(dir) unless Dir::exist?(dir)
  end

  Dir::chdir('idps') do
    idps.each do |idp|
      File.open("#{idp}.yml", 'w') do |f|
        f.write(YAML.dump(
          'entityId' => "http://stub_idp.acme.org/#{idp}/SSO/POST",
          'simpleId' => idp,
          'enabled' => true,
          'supportedLevelsOfAssurance' => [ 'LEVEL_1', 'LEVEL_2' ],
          'useExactComparisonType' => true
        ))
      end
    end
  end

  Dir::chdir('matching-services') do
    rps.each do |rp|
      File.open("#{rp}-ms.yml", 'w') do |f|
        f.write(YAML.dump(
          'entityId' => "http://#{rp}-ms.local/SAML2/MD",
          'healthCheckEnabled' => true,
          'uri' => "http://#{rp}-ms.local/matching-service/POST",
          'userAccountCreationUri' => "http://#{rp}-ms.local/unknown-user-attribute-query",
          'signatureVerificationCertificates' => [ { 'x509' => inline_cert(msa_signing_cert) } ],
          'encryptionCertificate' => { 'x509' => inline_cert(msa_encryption_cert) }
        ))
      end
    end
  end

  Dir::chdir('transactions') do
    rps.each do |rp|
      File.open("#{rp}.yml", 'w') do |f|
        f.write(YAML.dump(
          'entityId' => "http://#{rp}.local/SAML2/MD",
          'simpleId' => rp,
          'assertionConsumerServices' => [
            { 'uri' => "http://#{rp}.local/login", 'index' => 0, 'isDefault' => true }
          ],
          'levelsOfAssurance' => [ 'LEVEL_2' ],
          'matchingServiceEntityId' => "http://#{rp}-ms.local/SAML2/MD",
          'displayName' => 'Register for an identity profile',
          'otherWaysDescription' => 'access Dev RP',
          'serviceHomepage' => "http://#{rp}.local/home",
          'rpName' => 'Dev RP',
          'analyticsTransactionDescription' => 'DEV RP',
          'enabled' => true,
          'shouldHubSignResponseMessages' => true,
          'userAccountCreationAttributes' => [
            'FIRST_NAME',
            'FIRST_NAME_VERIFIED',
            'MIDDLE_NAME',
            'MIDDLE_NAME_VERIFIED',
            'SURNAME',
            'SURNAME_VERIFIED',
            'DATE_OF_BIRTH',
            'DATE_OF_BIRTH_VERIFIED',
            'CURRENT_ADDRESS',
            'CURRENT_ADDRESS_VERIFIED'
          ],
          'otherWaysToCompleteTransaction' => 'Do something else',
          'signatureVerificationCertificates' => [ { 'x509' => inline_cert(rp_signing_cert) } ],
          'encryptionCertificate' => { 'x509' => inline_cert(rp_encryption_cert) }
        ))
      end
    end
  end
end
