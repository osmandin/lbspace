package edu.yale.library.lbspace;

import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.impl.conn.PoolingHttpClientConnectionManager;

import java.util.concurrent.TimeUnit;

/**
 * Responsible for making the HTTP calls to ArchievesSpace
 * @author Osman Din
 */
public class HttpServiceUtil {

    private final PoolingHttpClientConnectionManager connectionManager = new PoolingHttpClientConnectionManager();

    private HttpClient httpClient;

    private static final int DEFAULT_MAX_PER_ROUTE = 5;

    private static final int IDLE_TIMEOUT = 15;

    private static final int SERVER_PORT = 8089;

    private static final String appUrl = buildAppRestUrl();

    public HttpServiceUtil() {
        setConnectionManagerProps(connectionManager);
        httpClient = HttpClients.custom().setConnectionManager(connectionManager).build();
    }

    private static void setConnectionManagerProps(final PoolingHttpClientConnectionManager cm) {
        cm.setMaxTotal(Integer.MAX_VALUE);
        //cm.setDefaultMaxPerRoute(DEFAULT_MAX_PER_ROUTE);
        cm.closeIdleConnections(IDLE_TIMEOUT, TimeUnit.SECONDS);
    }

    public HttpGet doGET(final String param) {
        final String url = appUrl + param + "/";
        HttpGet get = new HttpGet(url);
        return get;
    }

    public HttpPost doPOST(final String param) {
        final String url = appUrl + param + "/";
        HttpPost post = new HttpPost(url);
        return post;
    }

    private static String getProp(String s) {
        return System.getProperty(s);
    }

    private static String buildAppRestUrl() {
        return "http://devaspace.library.yale.edu:" +  SERVER_PORT; //TODO externalize
    }

    public HttpClient getHttpClient() {
        return httpClient;
    }

    public void setHttpClient(HttpClient httpClient) {
        this.httpClient = httpClient;
    }
}

