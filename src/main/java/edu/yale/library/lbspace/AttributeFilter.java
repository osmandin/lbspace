package edu.yale.library.lbspace;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathFactory;
import java.io.File;
import java.util.Collections;
import java.util.List;

public class AttributeFilter {

    private static Logger logger = LoggerFactory.getLogger(Exporter.class);

    private List<Attribute> purgeAttributes = Collections.emptyList();

    public AttributeFilter(List<Attribute> purgeAttributes) {
        this.purgeAttributes = purgeAttributes;
    }

    public void strip(final String dir) {
        final File parent = new File(dir);
        final File[] files = parent.listFiles();

        for (final File f : files) {
            if (f.isDirectory()) {
                final File[] subdir = f.listFiles();

                if (subdir == null) {
                    continue;
                }

                for (final File xmlFile : subdir) {
                    try {
                        //logger.debug("Replacing xml file:{}", xmlFile.getAbsolutePath());
                        replaceXml(xmlFile.getAbsolutePath(), xmlFile.getAbsolutePath());
                    } catch (Exception e) {
                        logger.error("Error amending XML for file:{}", e);
                        return;  //TODO validation error
                    }
                }
            }
        }
    }

    /**
     * Generic xml replacement code via Xpath
     *
     * @param filepath  directory to read
     * @param outputDir directory to write
     * @throws Exception
     */
    public void replaceXml(final String filepath, final String outputDir) throws Exception {
        final DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
        final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();
        final Document doc = docBuilder.parse(filepath);

        final XPath xpath = XPathFactory.newInstance().newXPath();

        for (Attribute attribute : purgeAttributes) {
//            String xPathExpressionAttr = "//*[contains(@" + attribute.getAttribute() +", /'" + attribute.getValue() +"/')]";
            String xPathExpressionAttr = "//*[contains(@" + attribute.getAttribute() +", " + attribute.getValue() +" )]";

            NodeList nodesAttr = (NodeList) xpath.evaluate(xPathExpressionAttr, doc, XPathConstants.NODESET);
            loopAttributes(nodesAttr, attribute.getValue(), attribute.getAttribute());
        }

        final TransformerFactory transformerFactory = TransformerFactory.newInstance();
        final Transformer transformer = transformerFactory.newTransformer();
        final DOMSource source = new DOMSource(doc);
        final StreamResult result = new StreamResult(new File(outputDir));
        transformer.transform(source, result);
    }


    private void loopAttributes(final NodeList nodesAttr, final String attribute, final String remove) {

        for(int i=0; i<nodesAttr.getLength(); i++) {
            for (int j = 0; j < nodesAttr.item(i).getAttributes().getLength(); j++) {
                final String p = nodesAttr.item(i).getAttributes().item(j).toString();
                if (p.contains(attribute) && p.length() > 10) { //FIXME replace with regex
                    //logger.debug("Replaced text:{} with:{}", textToFind, textToReplace);
                    nodesAttr.item(i).getAttributes().removeNamedItem(remove);
                }
            }
        }
    }

}
