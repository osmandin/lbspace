package edu.yale.library.lbspace;



import org.apache.commons.configuration.Configuration;
import org.apache.commons.configuration.PropertiesConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class PropertiesConfigurationUtil {

    private static final Logger logger = LoggerFactory.getLogger(PropertiesConfigurationUtil.class);

    /**
     * for general props
     */
    private static Configuration general;

    /**
     * For removing xml attribute
     */
    private static Configuration purgeConfig;

    /**
     * For getting login details
     */
    private static Configuration login;


    static {
        try {
            general = new PropertiesConfiguration("paths.properties");
            purgeConfig = new PropertiesConfiguration("purge.properties");
            login = new PropertiesConfiguration("connection.props");
        } catch (Exception e) {
            logger.error("Error setting property file", e);
        }
    }

    public static String getProperty(final String p) {
        return general.getProperty(p).toString();
    }

    public static Credentials getCredentials() {
        Credentials credentials = new Credentials();
        credentials.setPassword(login.getProperty("login_password").toString());
        credentials.setUrl(login.getProperty("login_url").toString());
        return credentials;
    }

    public static List<Attribute> getAttributes() {
        final Iterator<String> its = purgeConfig.getKeys();

        final List<Attribute> attributes = new ArrayList<>();

        while (its.hasNext()) {
            final String k = its.next();
            final String v = purgeConfig.getProperty(k).toString();

            final Attribute p = new Attribute();
            p.setAttribute(k);
            p.setValue(v);

            attributes.add(p);
        }

        return attributes;
    }
}