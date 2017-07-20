package uk.gov.ida.saml.core.test;

public interface TestEntityIds {
    String HUB_ENTITY_ID = "https://signin.service.gov.uk";
    String HUB_SECONDARY_ENTITY_ID = "https://signin.service.gov.uk/secondary";

    String TEST_RP = "http://www.test-rp.gov.uk/SAML2/MD";
    String TEST_RP_MS = "http://www.test-rp-ms.gov.uk/SAML2/MD";
    String HEADLESS_RP = "http://www.headless.gov.uk/SAML2/MD";
    String HEADLESS_RP_MS = "http://www.headless-ms.gov.uk/SAML2/MD";

    String STUB_IDP_ONE = "http://stub_idp.acme.org/stub-idp-one/SSO/POST";
    String STUB_IDP_TWO = "http://stub_idp.acme.org/stub-idp-two/SSO/POST";
    String STUB_IDP_THREE = "http://stub_idp.acme.org/stub-idp-three/SSO/POST";
    String STUB_IDP_FOUR = "http://stub_idp.acme.org/stub-idp-four/SSO/POST";
}
