package edu.yale.library.lbspace;

import org.hibernate.HibernateException;
import org.hibernate.SessionFactory;
import org.hibernate.cfg.Configuration;
import org.hibernate.service.ServiceRegistryBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class HibernateUtil {

    private static final Logger logger = LoggerFactory.getLogger(HibernateUtil.class);

    private static SessionFactory sessionFactory;

    /**
     * Builds org.hibernate.SessionFactory using a configuration file.
     *
     * @return org.hibernate.SessionFactory
     */
    private static SessionFactory buildSessionFactory() throws Exception {
        try {
            Configuration configuration = new Configuration();
            final String cfgXmlFile = new ConfigReader().getConfigFile();
            logger.debug("Using config file={}", cfgXmlFile);
            configuration.configure(cfgXmlFile);
            ServiceRegistryBuilder serviceRegistryBuilder = new ServiceRegistryBuilder().
                    applySettings(configuration.getProperties());
            logger.debug("Building session factory");
            SessionFactory sessionFactory = configuration.
                    buildSessionFactory(serviceRegistryBuilder.buildServiceRegistry());
            return sessionFactory;
        } catch (Exception ex) {
            logger.error("Exception encountered while building session factory");
            throw new Exception(ex);
        }
    }

    public static SessionFactory getSessionFactory() {
        if (sessionFactory == null) {
            synchronized (HibernateUtil.class) {
                if (sessionFactory == null) {
                    try {
                        sessionFactory = buildSessionFactory();
                    } catch (Exception e) {
                        logger.error("Error getting session factory", e);
                    }
                }
            }
        }
        return sessionFactory;
    }

    public static void shutdown() {
        logger.debug("Shutting down session factory");
        try {
            getSessionFactory().close();
        } catch (HibernateException e) {
            throw new HibernateException(e);
        }
    }

    private static class ConfigReader {
        public String getConfigFile() throws Exception {
            return "default.hibernate.cfg.xml";
        }
    }

}