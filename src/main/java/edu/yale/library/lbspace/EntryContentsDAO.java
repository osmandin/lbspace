package edu.yale.library.lbspace;

import org.hibernate.HibernateException;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.Transaction;
import org.slf4j.Logger;

import static org.slf4j.LoggerFactory.getLogger;

public class EntryContentsDAO {

    private final Logger logger = getLogger(this.getClass());

    private final SessionFactory sessionFactory = HibernateUtil.getSessionFactory();

    public EntryContentsDAO() {
        super();
    }

    public void persist(EntryContents transientInstance) {
        Session session = null;
        Transaction t = null;
        try {
            session = sessionFactory.openSession();
            // let's do it

            t = session.beginTransaction();

            int id= (Integer) session.save(transientInstance);


            session.flush();
            t.commit();
            logger.debug("Saved object id={}", id);
        } catch (RuntimeException re) {
            if (t != null) {
                t.rollback();
            }
            logger.error("Persist failed", re);
            throw re;
        } finally {
            try {
                if (session!= null) {
                    session.close();
                }
            } catch (HibernateException e) {
                logger.error("Error closing session", e);
            }
        }
    }

}