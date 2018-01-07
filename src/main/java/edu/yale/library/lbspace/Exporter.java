package edu.yale.library.lbspace;

import com.helger.schematron.pure.SchematronResourcePure;
import org.apache.http.HttpResponse;

import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.message.BasicNameValuePair;
import org.json.simple.parser.JSONParser;
import org.slf4j.*;

import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.URL;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

import javax.xml.XMLConstants;
import javax.xml.validation.*;

import com.helger.schematron.*;

import org.json.simple.*;

/**
 * Exports and validates. Relays filtering.
 */
public class Exporter {

    private static Logger logger = LoggerFactory.getLogger(Exporter.class);

    private String exportEndPoint = "";

    private int collectionId;

    private String modsOutputDir = "";

    private String eadOutputDir = "";

    private String MODS;

    private String EAD_YALE_TRANSFORM = "";

    private String SCHEMATRON= "";

    private List<Attribute> purgeAttributes = Collections.emptyList();

    private Credentials credentials = new Credentials();

    public Exporter(Credentials credentials, String exportEndPoint, int COLLECTION_ID, String modsOutputDir, String eadPath,
                    String modsPath, String eadYaleTransform, String schematron, List<Attribute> purgeAttributes) {
        this.credentials = credentials;
        this.exportEndPoint = exportEndPoint;
        this.collectionId = COLLECTION_ID;
        this.modsOutputDir = modsOutputDir;
        this.eadOutputDir = eadPath;
        this.MODS = modsPath;
        this.EAD_YALE_TRANSFORM = eadYaleTransform;
        this.SCHEMATRON = schematron;
        this.purgeAttributes = purgeAttributes;
    }

    public void execute() {
        logger.debug("Started raw EAD Export");

        final String token = authenticate(credentials.getUrl());

        logger.debug("Token:" + token);

        final String eadPath = exportEAD(token);

        // Do Yale transform
        final String transformedEAD = eadPath.replace(".xml", "-transformed.xml");
        transformEAD(eadPath, transformedEAD);

        // Validate the EAD file against the XSD schema
        if (!validateEAD(transformedEAD)) {
            return;
        }

        // Validate the EAD file against "Schema-tron"
        boolean result = validateXMLViaPureSchematron(new File(SCHEMATRON), new File(transformedEAD));
        logger.debug("Schema-tron validation result:{}", result);

        // Transform into a bunch of MODS files
        transformMODS(transformedEAD, modsOutputDir);

        // Validate 'em
        boolean modsValidation = validateMODS(modsOutputDir);

        if (!modsValidation) {
            logger.error("Mods validation failed!");
            return; //TODO update DB
        }

        logger.debug("Mods Validation OK. Path:{}", modsOutputDir);

        if (!purgeAttributes.isEmpty()){
            logger.debug("Stripping attributes.");
            AttributeFilter attributeFilter = new AttributeFilter(purgeAttributes);
            attributeFilter.strip(modsOutputDir);
        }
    }

    /**
     * Exports EAD and returns path
     * @param token auth
     * @return Path where the file is written
     */
    private String exportEAD(final String token) {

        final HttpServiceUtil httpServiceUtil = new HttpServiceUtil();
        final HttpGet httpGet = new HttpGet(exportEndPoint + collectionId + ".xml");
        httpGet.addHeader("X-ArchivesSpace-Session", token);

        StringBuffer sb = new StringBuffer();

        final Date date = new Date();
        long time = date.getTime();

        final String path = eadOutputDir + collectionId + "-" + time + ".xml";

        try {
            final PrintWriter out = new PrintWriter(path);
            final HttpResponse response = httpServiceUtil.getHttpClient().execute(httpGet);

            logger.debug("EAD service response:{}", response.getStatusLine());

            final BufferedReader br = new BufferedReader(
                    new InputStreamReader((response.getEntity().getContent())));

            String output;

            while (!(output = br.readLine()).contains("</ead>")) {
                sb.append(output);
                sb.append(System.getProperty("line.separator"));
            }

            sb.append(output);
            out.println(sb.toString());
            out.flush();
            out.close();

            logger.debug("Done reading");

            //JSONObject json = (JSONObject)new JSONParser().parse(sb.toString());
            //final String session =  (String) json.get("session");

            return path;

        } catch (Exception e) {
            logger.error("Error", e);
        }

        return "";
    }

    /**
     * Runs transform to be RAW_EAD compliant
     */
    public void transformEAD(String file, String output) {
        try {
            final TransformerFactory tFactory = new net.sf.saxon.TransformerFactoryImpl();
            final Source xslt = new StreamSource(new File(EAD_YALE_TRANSFORM));
            final Transformer transformer = tFactory.newTransformer(xslt);
            final Source xmlText = new StreamSource(new File(file));
            transformer.transform(xmlText,new StreamResult(new File(output)));
        } catch (TransformerException e) {
            logger.error("Error transforming to MODS", e);
        }
    }

    /**
     * Validate against the RAW_EAD schema
     */
    public boolean validateEAD(final String xmlFileSrc) {
        try {
            logger.debug("Validating the local RAW_EAD transformation");
            final URL schemaFile = new URL("http://www.loc.gov/ead/ead.xsd");
            final Source xmlFile = new StreamSource(new File(xmlFileSrc));
            final SchemaFactory schemaFactory = SchemaFactory
                    .newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
            final Schema schema = schemaFactory.newSchema(schemaFile);
            final Validator validator = schema.newValidator();
            //validator.validate(xmlFile);
            logger.debug("File:{} is valid", xmlFile.getSystemId());
            return true;
        } catch (Exception e) { //FIXME
            logger.error("Error", e);
        }

        return false;
    }

    /**
     * Runs MODS transform.
     */
    public void transformMODS(final String src, final String modsDir) {

        logger.debug("Transforming to MODS file:{} with dir:{}", src, modsDir);

        try {

            final File file = new File(modsDir);

            if (!file.isDirectory()) {
                try {
                    Files.createDirectory(Paths.get(modsDir));
                } catch (IOException e) {
                    logger.error("Must create dir. Was passed:{}", src);
                    return;
                }

            }

            final TransformerFactory tFactory = new net.sf.saxon.TransformerFactoryImpl();
            final Source xslt = new StreamSource((MODS));
            final Transformer transformer = tFactory.newTransformer(xslt);
            final Source xmlText = new StreamSource(new File(src));
            transformer.transform(xmlText, new StreamResult(new File(modsDir)));
        } catch (TransformerException e) {
            logger.error("Error transforming to MODS", e);
        }
    }

    /**
     * Validate RAW_EAD against Schematron
     */
    public static boolean validateXMLViaPureSchematron (final File aSchematronFile, final File aXMLFile)
    {
        try {
            final ISchematronResource aResPure = SchematronResourcePure.fromFile(aSchematronFile);
            if (!aResPure.isValidSchematron ())
                throw new IllegalArgumentException ("Invalid Schematron!");
            return aResPure.getSchematronValidity(new StreamSource(aXMLFile)).isValid ();
        } catch (Exception e) {
            logger.error("Error", e);
        }

        return true;
    }

    /**
     * Bulk validate the MODS older against the MODS schema
     */
    public boolean validateMODS(final String dirPath) {
        // iterate each directory and verify MODS works

        boolean validates;

        final File dir = new File(dirPath);
        final File[] directoryListing = dir.listFiles();

        if (directoryListing != null) {
            for (final File child : directoryListing) {
                // Do something with child

                if (!child.getAbsolutePath().contains(".xml")) { //TODO apply file filter here
                    continue;
                }

                validates = singleValidateMODS(child.getAbsolutePath());

                if (!validates) {
                    return false;
                }
            }
        }

        return true;
    }

    // TODO clean up so that instantiation does not repeat
    public boolean singleValidateMODS(final String xmlFileSrc) {
        try {
            logger.debug("Validating the local RAW_EAD transformation");
            final URL schemaFile = new URL("http://www.loc.gov/ead/ead.xsd");
            final Source xmlFile = new StreamSource(new File(xmlFileSrc));
            final SchemaFactory schemaFactory = SchemaFactory
                    .newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
            final Schema schema = schemaFactory.newSchema(schemaFile);
            final Validator validator = schema.newValidator();
            validator.validate(xmlFile);
            logger.debug("File OK:{}", xmlFile.getSystemId());
        } catch (Exception e) { //FIXME
            logger.debug("Failed validation:{}", xmlFileSrc, e);
            return false;
        }

        logger.debug("Validation complete");
        return true;
    }

    /**
     * Commit the files to git
     * (Alt, write to a share that's SCM)
     */
    private void gitAnalysis() {
        // Do a Git commit

        // Analyze what changed

        // Copy to shared folder
    }


    /**
     * Update Ladybird (pamoja) so that a cron can pick it up
     */
    public void updateDB() {
        logger.debug("Saving entry to database");
        final Entry entry = new Entry();
        entry.setNotes("Export Complete");
        EntryDAO entryDAO = new EntryDAO();
        entryDAO.persist(entry);
    }

    private String authenticate(final String loginUrl) {
        // Make the request
        final HttpServiceUtil httpServiceUtil = new HttpServiceUtil();

        final HttpPost httpPost = new HttpPost(loginUrl);
        final List<NameValuePair> nvps = new ArrayList<NameValuePair>();
        nvps.add(new BasicNameValuePair("password", credentials.getPassword()));
        httpPost.setEntity(new UrlEncodedFormEntity(nvps, Charset.defaultCharset()));
        try {
            final HttpResponse response = httpServiceUtil.getHttpClient().execute(httpPost);

            logger.debug("Auth handshake status:{}", response.getStatusLine());

            final BufferedReader br = new BufferedReader(
                    new InputStreamReader((response.getEntity().getContent())));
            StringBuffer sb = new StringBuffer();
            String output = "";
            while ((output = br.readLine()) != null) {
                sb.append(output);
                //   System.out.println(sb.toString());
            }

            JSONObject json = (JSONObject)new JSONParser().parse(sb.toString());
            final String session =  (String) json.get("session");

            if (session == null) {
                //TODO
            }

            return session;
        } catch (Exception e) {
            logger.error("Error auth", e);
        }

        return "";
    }

}