package certificates.values;

import com.google.common.base.Throwables;
import org.apache.commons.io.IOUtils;

import java.io.IOException;

public class CACertificates {
    private static String readCertificateFile(String name) {
        try {
            return IOUtils.toString(CACertificates.class.getResourceAsStream("/ca-certificates/" + name));
        } catch (IOException e) {
            throw Throwables.propagate(e);
        }
    }

    public static final String TEST_ROOT_CA = readCertificateFile("ida-root-ca.pem.test");

    public static final String TEST_METADATA_CA = readCertificateFile("ida-metadata-ca.pem.test");

    public static final String TEST_IDP_CA = readCertificateFile("ida-intermediary-ca.pem.test");

    public static final String TEST_RP_CA = readCertificateFile("ida-intermediary-rp-ca.pem.test");

    public static final String TEST_CORE_CA = readCertificateFile("idap-core-ca.pem.test");

    // New generation of CAs

    public static final String TEST_VERIFY_ROOT_CA = readCertificateFile("verify-root-ca.pem.test");

    public static final String TEST_VERIFY_ROOT_CA_EC = readCertificateFile("verify-root-ca-ec.pem.test");

    public static final String TEST_VERIFY_METADATA_CA = readCertificateFile("verify-metadata-ca.pem.test");

    public static final String TEST_VERIFY_METADATA_CA_EC = readCertificateFile("verify-metadata-ca-ec.pem.test");

    public static final String TEST_VERIFY_IDP_CA = readCertificateFile("verify-intermediary-ca.pem.test");

    public static final String TEST_VERIFY_RP_CA = readCertificateFile("verify-intermediary-rp-ca.pem.test");

    public static final String TEST_VERIFY_CORE_CA = readCertificateFile("verify-core-ca.pem.test");

    public static final String TEST_VERIFY_CORE_CA_EC = readCertificateFile("verify-core-ca-ec.pem.test");
}
