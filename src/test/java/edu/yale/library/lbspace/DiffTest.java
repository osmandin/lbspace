package edu.yale.library.lbspace;

/**
 * http://stackoverflow.com/questions/16540318/compare-two-xml-strings-ignoring-element-order
 *
 * Created by osmandin on 9/11/16.
 */

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.junit.Assert;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.xmlunit.builder.DiffBuilder;
import org.xmlunit.builder.Input;
import org.xmlunit.diff.*;

import javax.xml.transform.Source;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.*;



public class DiffTest {

    private static Logger logger = LoggerFactory.getLogger(DiffTest.class);


    @Test
    public void test() {
        Source control = Input.fromFile("/Users/odin/Documents/mods-dir/mods-mssa.ms.2004/mssa.ms.2004-ref999.xml").build();
        Source test = Input.fromFile("/Users/odin/Documents/mods-dir/archive-5240-backup/mssa.ms.2004-ref999.xml").build();
        //DifferenceEngine diff = new DOMDifferenceEngine();
        Diff diff = DiffBuilder.compare(control)
                .withTest(test)
                .withNodeMatcher(new DefaultNodeMatcher(ElementSelectors.byNameAndText))
                .build();

        System.out.println(diff.toString());

        Iterator<Difference> it = diff.getDifferences().iterator();

        while (it.hasNext()) {
            Difference d = it.next();
            System.out.println(d.getComparison());
        }


        assert !diff.hasDifferences();
    }

    @Test
    public void test2() {
        Source control = Input.fromFile("/Users/odin/Documents/mods-dir/lyrass/mods-mssa.ms.2004/mssa.ms.2004-ref3109.xml").build();
        Source test = Input.fromFile("/Users/odin/Documents/mods-dir/archive-5240-backup/mssa.ms.2004-ref3109.xml").build();
        //DifferenceEngine diff = new DOMDifferenceEngine();
        DifferenceEngine diff = new DOMDifferenceEngine();
        diff.addDifferenceListener(new ComparisonListener() {
            public void comparisonPerformed(Comparison comparison, ComparisonResult outcome) {
                ComparisonType t = comparison.getType();
                System.out.println("Diff:" + t.getDescription());
                System.out.println("XPath:" + comparison.getTestDetails().getXPath());
                System.out.println("Comparison:" + comparison.getTestDetails().getValue());
                System.out.println("Comparison:" + comparison.getControlDetails().getValue());
                System.out.println("--------------");
            }
        });

        diff.compare(control, test);

    }

    @Test
    public void test_local() {
        Source control = Input.fromFile("/Users/odin/Downloads/IdeaProjects/lbspace/a.xml").build();
        Source test = Input.fromFile("/Users/odin/Downloads/IdeaProjects/lbspace/b.xml").build();
        //DifferenceEngine diff = new DOMDifferenceEngine();
        DifferenceEngine diff = new DOMDifferenceEngine();
        diff.addDifferenceListener(new ComparisonListener() {
            public void comparisonPerformed(Comparison comparison, ComparisonResult outcome) {
                ComparisonType t = comparison.getType();
                System.out.println("Diff:" + t.getDescription());
                System.out.println("XPath:" + comparison.getTestDetails().getXPath());
                System.out.println("Comparison:" + comparison.getTestDetails().getValue());
                System.out.println("Comparison:" + comparison.getControlDetails().getValue());
                System.out.println("--------------");
            }
        });

        diff.compare(control, test);

    }

    @Test
    public void test_full() {

        final List<String> fileNames = new ArrayList<>();

        //Source control = Input.fromFile("/Users/odin/Documents/mods-dir/mods-mssa.ms.2004/mssa.ms.2004-ref999.xml").build();
        final String dir2 = "/Users/odin/Documents/mods-dir/archive-5240-backup/";
        //DifferenceEngine diff = new DOMDifferenceEngine();
        final DifferenceEngine diff = new DOMDifferenceEngine();
        final File dir = new File("/Users/odin/Documents/mods-dir/mods-mssa.ms.2004/");
        final File[] files = dir.listFiles();

        final Map<String, String> changedFiles = new HashMap<>();

        final StringBuffer sb = new StringBuffer();


        diff.addDifferenceListener(new ComparisonListener() {
            public void comparisonPerformed(Comparison comparison, ComparisonResult outcome) {

                final ComparisonType t = comparison.getType();


                // System.out.println(comparison.getTestDetails().getXPath());

                if (t == ComparisonType.TEXT_VALUE) {
                    //System.out.println("File:" + fileNames.get(fileNames.size() - 1));
                    //System.out.println("Element:" + comparison.getTestDetails().getXPath());
                    //System.out.println("Change: " + comparison.getTestDetails().getValue());
                    //System.out.println("----");
                    changedFiles.put(fileNames.get(fileNames.size() - 1), "");
                } else { //e.g., ELEMENT_NUM_ATTRIBUTES OR ATTR_NAME_LOOKUP
                }

                sb.append(t.getDescription() + ":" + comparison.getTestDetails().getXPath() + "\n");

            }
        });


        for (final File f : files) {
            Source control = Input.fromFile("/Users/odin/Documents/mods-dir/mods-mssa.ms.2004/" + f.getName()).build();
            Source test = Input.fromFile(dir2 + f.getName()).build();
            //logger.info("File: {}", f.getName());
            sb.append("File: " + f.getName() + "\n");
            fileNames.add(f.getName());
            diff.compare(control, test);
            sb.append("\n");
        }

        try {
            FileUtils.writeStringToFile(new File("changeset.txt"), sb.toString());
        } catch (IOException e) {
            e.printStackTrace();
        }


        System.out.println("Changed files:" + changedFiles);

        if (true) {
            return;
        }

        // feed it now to sqlserver

        EntryDAO entryDAO = new EntryDAO();

        Entry e = new Entry();
        e.setDate(new Date());
        e.setCollectionName("5204");
        e.setTransactionId(1);

        File file = new File("/tmp/5240.zip");
        try {
            InputStream is = new FileInputStream(file);
            byte[] bytes = IOUtils.toByteArray(is);
            e.setExport_file(bytes);


            System.out.println("Byte array size: " + bytes.length);
        } catch (IOException e1) {
            e1.printStackTrace();
        }

        entryDAO.persist(e);

        EntryContentsDAO entryContentsDAO = new EntryContentsDAO();

        final Set<String> changedF = changedFiles.keySet();

        for (final String f : changedF) {
            EntryContents ec = new EntryContents();
            ec.setTransactionId(1);
            ec.setFileName(f);
            e.setDate(new Date());
            entryContentsDAO.persist(ec);
        }

    }

}