package edu.yale.library.lbspace;


import java.io.File;
import java.util.List;

import static java.lang.Integer.parseInt;

public class Main {

    /**
     * Driver
     * @param args none
     */
    public static void main (String args[]) {
        final String export = value("export_url");
        final String ead_output_dir = value("ead_output_dir");
        String mods_output_dir = value("mods_output_dir") + File.separator + value("collection");
        final int collection = parseInt(value("collection"));
        final String mods = value("mods_xsl_path");
        final String ead = value("ead_yale_transform_path");
        final String schematron = value("schematron_path");
        final List<Attribute> attributesToPurge = PropertiesConfigurationUtil.getAttributes();
        final Credentials credentials = PropertiesConfigurationUtil.getCredentials();

        Exporter exporter = new Exporter(credentials, export, collection, mods_output_dir, ead_output_dir, mods, ead, schematron, attributesToPurge);
        exporter.execute();

    }

    private static String value(final String id){
        return PropertiesConfigurationUtil.getProperty(id);
    }
}
