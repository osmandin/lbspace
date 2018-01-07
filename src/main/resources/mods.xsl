<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:math="http://www.w3.org/2005/xpath-functions/math"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:ead="urn:isbn:1-931666-22-9"
                xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink"
                exclude-result-prefixes="#all" version="3.0">

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jul 14, 2014</xd:p>
            <xd:p><xd:b>Author:</xd:b> Mark Custer</xd:p>
            <xd:p>The yale.aspace_v112_to_yalebpgs-not_for_YFAD.xsl style sheet should be run on the
                ASpace EAD output before this style sheet is used.</xd:p>
            <xd:ul>
                <xd:li>
                    <xd:b>Organized into four sections:</xd:b>
                </xd:li>
                <xd:li>1: Parameters and global variables</xd:li>
                <xd:li>2: Result documents (context tree, collection level, and every level of
                    description of the DSC gets its own MODS record)</xd:li>
                <xd:li>3: MODS elements (i.e. EAD to MODS mapping)</xd:li>
                <xd:li>4: Templates to build the context tree (currently in HTML, but could change
                    to JSON, XML, RDF, whatever's needed)</xd:li>
            </xd:ul>
        </xd:desc>
    </xd:doc>

    <!-- to do:

        to make DACS single-level minimum record compliant....
                    compute the physdesc
                    make sure to inherit title / data information from the first ancestor that has one of those, if missing at that level of description
                    add the "collection creator" in the Host section
                    inherit the nearest ancestor with a language note
                   add more information about the repository? (or just link to this via an EAG, eventually?)

                    add another EAD-snippet that separates the inherited data, to be somewhat explicit about how the MODS record is created?

                    use the UI/delivery platrom to show the scope and content notes for ancestors in the breadcrumb (see NYPL for an example of this; hover over the "i" icons).

        Add parameters to control what gets serialized to MODS:  example, pass an ID, and another flag whether to get only that level or that level plus all of the children
        allow multiple IDs to be passed in an array.

        where to put dao's ???

       combine repistory-ID, colleciton-ID, ref-ID, to make globally unique IDs?
        -->

    <xsl:output encoding="UTF-8" indent="yes" method="xml"/>

    <!-- change this parameter to a list of options to determine what elements (not) to inherit.
        for now, I'm just adding a single option so that we can choose not to inherit dates, as well -->
    <xsl:param name="inherit-dates-option"  as="xs:boolean" select="false()"/>

    <!-- the user must specify what elements are to be stripped when calling the style sheet-->
    <xsl:param name="element-to-strip"/>
    <xsl:template match="*[local-name = $element-to-strip]" priority="10"/>

    <!-- this is done for a local requirement; otherwise I'd set it to false, since it results in bloated MODS files-->
    <xsl:param name="paramertize-dates-option" select="true()" as="xs:boolean"/>

    <!-- adding this, since I can't always rely on xsl:copy in this finding aid anymore-->
    <xsl:template match="@* | node()" mode="ead-snippet-copy">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>


    <!-- SECTION 1 -->
    <!-- SECTION 1 -->
    <!-- SECTION 1 -->
    <xsl:param name="outputdirectory">
        <xsl:value-of select="concat('mods-', $collection-ID, '/')"/>
    </xsl:param>
    <xsl:variable name="repository-ID"
                  select="ead:ead/ead:eadheader/ead:eadid[1]/@mainagencycode/normalize-space()"/>
    <xsl:variable name="collection-ID" select="ead:ead/ead:eadheader/ead:eadid[1]/normalize-space()"/>


    <!-- SECTION 2 -->
    <!-- SECTION 2 -->
    <!-- SECTION 2 -->

    <xsl:template match="/">
        <!-- the following named template creates the context tree document-->
        <xsl:call-template name="EAD-to-MODS-context-tree"/>
        <!-- next, we just need to call the archdesc section of the finding aid, which contains every level of description, starting with the collection level first.-->
        <xsl:apply-templates select="ead:ead/ead:archdesc"/>
    </xsl:template>

    <xsl:template name="EAD-to-MODS-context-tree">
        <xsl:result-document exclude-result-prefixes="xsl ead"
                             href="{$outputdirectory}{$collection-ID}-contextTree.xml" encoding="UTF-8" indent="yes">
            <mods:mods xmlns:mods="http://www.loc.gov/mods/v3"
                       xmlns:xlink="http://www.w3.org/TR/xlink"
                       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                       xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/mods.xsd">
                <mods:extension>
                    <!-- or create this in JSON or RDF, etc? -->
                    <div id="tree">
                        <head>
                            <xsl:value-of
                                    select="normalize-space(/ead:ead/ead:archdesc/ead:did/ead:unittitle)"
                                    />
                        </head>
                        <ul>
                            <xsl:apply-templates select="//ead:c01 | //ead:dsc/ead:c"
                                                 mode="treeData"/>
                        </ul>
                    </div>
                </mods:extension>
            </mods:mods>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="ead:archdesc">
        <xsl:result-document exclude-result-prefixes="xsl ead"
                             href="{$outputdirectory}{$collection-ID}.xml" encoding="UTF-8" indent="yes">
            <mods:mods xmlns:mods="http://www.loc.gov/mods/v3"
                       xmlns:xlink="http://www.w3.org/TR/xlink"
                       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                       xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/mods.xsd">
                <xsl:apply-templates select="/ead:ead/ead:eadheader/ead:eadid"/>
                <xsl:apply-templates/>
                <mods:extension displayLabel="EAD">
                    <xsl:copy-of select="/ead:ead"/>
                </mods:extension>
            </mods:mods>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="ead:*[ead:did and ancestor::ead:dsc]">
        <xsl:param name="filename">
            <xsl:value-of select="concat($collection-ID, '-', normalize-space(@id))"/>
        </xsl:param>
        <xsl:result-document exclude-result-prefixes="xsl ead"
                             href="{$outputdirectory}{$filename}.xml" encoding="UTF-8" indent="yes">
            <mods:mods xmlns:mods="http://www.loc.gov/mods/v3"
                       xmlns:xlink="http://www.w3.org/TR/xlink"
                       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                       xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/mods.xsd">

                <xsl:apply-templates/>

                <xsl:if test="not(ead:accessrestrict)">
                    <xsl:choose>
                        <xsl:when test="ancestor::*[ead:accessrestrict][1]">
                            <xsl:apply-templates
                                    select="ancestor::*[ead:accessrestrict][1]/ead:accessrestrict"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates
                                    select="ancestor::ead:archdesc/ead:descgrp/ead:accessrestrict"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:if test="not(ead:userestrict)">
                    <xsl:choose>
                        <xsl:when test="ancestor::*[ead:userestrict][1]">
                            <xsl:apply-templates
                                    select="ancestor::*[ead:userestrict][1]/ead:userestrict"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates
                                    select="ancestor::ead:archdesc/ead:descgrp/ead:userestrict"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:if test="not(ead:originalsloc)">
                    <xsl:apply-templates select="ancestor::*[ead:originalsloc][1]/ead:originalsloc"
                            />
                </xsl:if>
                <xsl:if test="not(ead:prefercite)">
                    <mods:note type="preferredCitation">
                        <xsl:call-template name="combine-that-title-and-date-NO-HTML">
                            <xsl:with-param name="from-treeData-mode" select="false()"
                                            as="xs:boolean"/>
                        </xsl:call-template>
                        <xsl:text>. </xsl:text>
                        <xsl:choose>
                            <xsl:when test="ancestor::*[ead:prefercite][1]">
                                <!-- using an unused mode here so that it won't be processed as normal, with a mods:note being utilized again-->
                                <xsl:apply-templates
                                        select="ancestor::*[ead:userestrict][1]/ead:prefercite"
                                        mode="noMODS-noEADHEAD"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates
                                        select="ancestor::ead:archdesc/ead:descgrp/ead:prefercite"
                                        mode="noMODS-noEADHEAD"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </mods:note>
                </xsl:if>
                <mods:extension displayLabel="EAD-snippet">
                    <xsl:copy>
                        <xsl:apply-templates select="@*" mode="ead-snippet-copy"/>
                        <xsl:if test="not(@audience)">
                            <xsl:copy select="ancestor::*[@audience]/@audience"/>
                        </xsl:if>
                        <!-- had to remove "copy of" since we need to inherit physloc notes, as well-->
                        <xsl:apply-templates
                                select="
                                * except *[local-name() = ('c',
                                'c01',
                                'c02',
                                'c03',
                                'c04',
                                'c05',
                                'c06',
                                'c07',
                                'c08',
                                'c09',
                                'c10',
                                'c11',
                                'c12')]"
                                mode="ead-snippet-copy"/>
                        <xsl:if test="not(ead:accessrestrict)">
                            <xsl:choose>
                                <xsl:when test="ancestor::*[ead:accessrestrict][1]">
                                    <xsl:for-each
                                            select="ancestor::*[ead:accessrestrict][1]/ead:accessrestrict">
                                        <xsl:copy>
                                            <xsl:attribute name="altrender">
                                                <xsl:text>inherited</xsl:text>
                                            </xsl:attribute>
                                            <xsl:copy-of select="@* except @altrender | node()"/>
                                        </xsl:copy>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:for-each
                                            select="ancestor::ead:archdesc/ead:descgrp/ead:accessrestrict">
                                        <xsl:copy>
                                            <xsl:attribute name="altrender">
                                                <xsl:text>inherited</xsl:text>
                                            </xsl:attribute>
                                            <xsl:copy-of select="@* except @altrender | node()"/>
                                        </xsl:copy>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                        <xsl:if test="not(ead:userestrict)">
                            <xsl:choose>
                                <xsl:when test="ancestor::*[ead:userestrict][1]">
                                    <xsl:for-each
                                            select="ancestor::*[ead:userestrict][1]/ead:userestrict">
                                        <xsl:copy>
                                            <xsl:attribute name="altrender">
                                                <xsl:text>inherited</xsl:text>
                                            </xsl:attribute>
                                            <xsl:copy-of select="@* except @altrender | node()"/>
                                        </xsl:copy>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:for-each
                                            select="ancestor::ead:archdesc/ead:descgrp/ead:userestrict">
                                        <xsl:copy>
                                            <xsl:attribute name="altrender">
                                                <xsl:text>inherited</xsl:text>
                                            </xsl:attribute>
                                            <xsl:copy-of select="@* except @altrender | node()"/>
                                        </xsl:copy>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                        <xsl:if test="not(ead:originalsloc)">
                            <xsl:for-each select="ancestor::*[ead:originalsloc][1]/ead:originalsloc">
                                <xsl:copy>
                                    <xsl:attribute name="altrender">
                                        <xsl:text>inherited</xsl:text>
                                    </xsl:attribute>
                                    <xsl:copy-of select="@* except @altrender | node()"/>
                                </xsl:copy>
                            </xsl:for-each>
                        </xsl:if>
                        <xsl:if test="not(ead:prefercite)">
                            <xsl:element name="prefercite" namespace="urn:isbn:1-931666-22-9">
                                <xsl:attribute name="altrender">
                                    <xsl:text>constructed</xsl:text>
                                </xsl:attribute>
                                <xsl:element name="p" namespace="urn:isbn:1-931666-22-9">
                                    <xsl:call-template name="combine-that-title-and-date-NO-HTML">
                                        <xsl:with-param name="from-treeData-mode" select="false()"
                                                        as="xs:boolean"/>
                                    </xsl:call-template>
                                    <xsl:text>. </xsl:text>
                                    <xsl:choose>
                                        <xsl:when test="ancestor::*[ead:prefercite][1]">
                                            <xsl:apply-templates
                                                    select="ancestor::*[ead:userestrict][1]/ead:prefercite"
                                                    mode="noMODS-noEADHEAD"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:apply-templates
                                                    select="ancestor::ead:archdesc/ead:descgrp/ead:prefercite"
                                                    mode="noMODS-noEADHEAD"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:element>
                            </xsl:element>
                        </xsl:if>
                    </xsl:copy>
                </mods:extension>

                <mods:relatedItem type="host">
                    <mods:identifier type="contextTree-file">
                        <xsl:value-of select="concat($collection-ID, '-contextTree.xml')"/>
                    </mods:identifier>
                    <mods:identifier type="contextTree-branch">
                        <xsl:value-of select="concat($collection-ID, '/', @id)"/>
                    </mods:identifier>
                    <!-- add parent info here, or elsewhere? -->
                    <mods:identifier type="parentID">
                        <xsl:value-of
                                select="
                                if (../@id) then
                                    concat($collection-ID, '/', ../@id)
                                else
                                    $collection-ID"
                                />
                    </mods:identifier>
                    <mods:identifier type="z-index">
                        <xsl:value-of
                                select="
                                count(preceding-sibling::*[local-name() = ('c',
                                'c01',
                                'c02',
                                'c03',
                                'c04',
                                'c05',
                                'c06',
                                'c07',
                                'c08',
                                'c09',
                                'c10',
                                'c11',
                                'c12')]) + 1"
                                />
                    </mods:identifier>

                    <xsl:if test="ead:did/ead:container">
                        <mods:part>
                            <xsl:apply-templates select="ead:did/ead:container"/>
                        </mods:part>
                    </xsl:if>

                    <xsl:apply-templates
                            select="/ead:ead/ead:archdesc[1]/ead:did[1]/ead:unittitle[1]"/>
                    <xsl:apply-templates select="/ead:ead/ead:archdesc[1]/ead:did[1]/ead:unitid[1]"/>
                    <xsl:apply-templates
                            select="/ead:ead/ead:archdesc[1]/ead:did[1]/ead:origination"/>
                    <xsl:apply-templates
                            select="/ead:ead/ead:archdesc[1]/ead:did[1]/ead:langmaterial"/>

                    <mods:location>
                        <mods:physicalLocation displayLabel="Yale Collection">
                            <xsl:apply-templates
                                    select="
                                    if (ead:did/ead:repository)
                                    then
                                        ead:did/ead:repository/ead:corpname
                                    else
                                        /ead:ead/ead:archdesc[1]/ead:did[1]/ead:repository[1]/ead:corpname[1]/normalize-space()"
                                    />
                        </mods:physicalLocation>
                    </mods:location>
                </mods:relatedItem>

            </mods:mods>
        </xsl:result-document>
    </xsl:template>


    <!-- SECTION 3 -->
    <!-- SECTION 3 -->
    <!-- SECTION 3 -->

    <xsl:template match="ead:head">
        <xsl:apply-templates/>
        <xsl:text>: </xsl:text>
    </xsl:template>

    <xsl:template match="ead:*" mode="noMODS-noEADHEAD">
        <xsl:apply-templates select="* except ead:head"/>
    </xsl:template>

    <!-- data to hide from primary MODS output -->
    <xsl:template match="ead:did/ead:head | ead:dsc/ead:head"/>
    <xsl:template match="ead:controlaccess//ead:head"/>
    <xsl:template match="ead:descgrp//ead:head"/>
    <xsl:template match="ead:controlaccess//ead:p"/>
    <xsl:template match="ead:did/ead:repository"/>

    <xsl:template match="ead:dao | ead:daogrp"/>

    <xsl:template match="ead:did" mode="ead-snippet-copy">
        <xsl:copy>
            <xsl:copy-of select="@* | *"/>
            <xsl:if test="not(ead:unittitle)">
                <xsl:copy select="ancestor::*[ead:did/ead:unittitle][1]/ead:did/ead:unittitle">
                    <xsl:attribute name="altrender">
                        <xsl:text>inherited</xsl:text>
                    </xsl:attribute>
                    <xsl:copy-of select="@* except @altrender | node()"/>
                </xsl:copy>
            </xsl:if>
            <xsl:if test="not(ead:unitdate) and $inherit-dates-option eq true()">
                <xsl:copy select="ancestor::*[ead:did/ead:unitdate][1]/ead:did/ead:unitdate">
                    <xsl:attribute name="altrender">
                        <xsl:text>inherited</xsl:text>
                    </xsl:attribute>
                    <xsl:copy-of select="@* except @altrender | node()"/>
                </xsl:copy>
            </xsl:if>
            <!-- added for materials held elsewhere, so we need to inherit the physloc information-->
            <xsl:if test="not(ead:physloc)">
                <xsl:copy select="ancestor::*[ead:did/ead:physloc][1]/ead:did/ead:physloc">
                    <xsl:attribute name="altrender">
                        <xsl:text>inherited</xsl:text>
                    </xsl:attribute>
                    <xsl:copy-of select="@* except @altrender | node()"/>
                </xsl:copy>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:did">
        <xsl:apply-templates
                select="
                * except (ead:container,
                ead:unitdate,
                ead:unittitle)"/>
        <xsl:choose>
            <xsl:when test="ead:unittitle/normalize-space() = '' or not(ead:unittitle)">
                <xsl:apply-templates
                        select="../ancestor::*[ead:did/ead:unittitle/normalize-space() ne ''][1]/ead:did/ead:unittitle"
                        />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="ead:unittitle"/>
            </xsl:otherwise>
        </xsl:choose>


        <xsl:call-template name="construct-title-for-HTML"/>

        <!-- test to make sure this produces results as expected.-->
        <xsl:if test="$inherit-dates-option eq true() and (ead:unitdate/normalize-space() = '' or not(ead:unitdate))">
            <xsl:apply-templates
                    select="../ancestor::*[ead:did/ead:unitdate/normalize-space() ne ''][1]/ead:did/ead:unitdate"
                    />
        </xsl:if>
        <xsl:apply-templates select="ead:unitdate[not(contains(., 'undated'))][not(@type = 'bulk')]">
            <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
            <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
            <xsl:sort select="." data-type="text" order="ascending"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="ead:unitdate[(contains(., 'undated'))]">
            <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
            <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
            <xsl:sort select="." data-type="text" order="ascending"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="ead:unitdate[@type = 'bulk']">
            <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
            <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
            <xsl:sort select="." data-type="text" order="ascending"/>
        </xsl:apply-templates>

        <!-- added for materials held elsewhere, so we need to inherit the information-->
        <xsl:if test="not(ead:physloc)">
            <xsl:choose>
                <xsl:when test="ancestor::*[ead:did/ead:physloc][1]">
                    <xsl:apply-templates
                            select="ancestor::*[ead:did/ead:physloc][1]/ead:did/ead:physloc"/>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <xsl:template match="ead:container">
        <mods:detail>
            <xsl:attribute name="type">
                <xsl:value-of select="@type"/>
            </xsl:attribute>
            <mods:caption>
                <xsl:apply-templates/>
            </mods:caption>
        </mods:detail>
    </xsl:template>

    <!-- this does not allow roundtripping of the data, obviously, but it follows the DLF Aquifer guidelines -->
    <xsl:template match="ead:abstract | ead:scopecontent">
        <mods:abstract>
            <xsl:apply-templates/>
        </mods:abstract>
    </xsl:template>

    <xsl:template match="ead:unittitle">
        <mods:titleInfo>
            <mods:title>
                <xsl:apply-templates/>
            </mods:title>
        </mods:titleInfo>
    </xsl:template>

    <xsl:template match="ead:unittitle" mode="treeData">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:template match="ead:unittitle" mode="HTML-title">
        <mods:titleInfo otherType="HTML-title">
            <mods:title>
                <xsl:apply-templates mode="HTML-title"/>
            </mods:title>
        </mods:titleInfo>
    </xsl:template>

    <!-- if contains ca. (or circa) add:
         qualifier="approximate" ?
         -->
    <xsl:template match="ead:unitdate">
        <mods:originInfo>
            <xsl:attribute name="displayLabel">
                <xsl:value-of
                        select="
                        if (@type = 'bulk') then
                            'Bulk Dates'
                        else
                            'Dates'"
                        />
            </xsl:attribute>
            <xsl:apply-templates select="@normal"/>
            <mods:dateCreated>
                <xsl:apply-templates/>
            </mods:dateCreated>
        </mods:originInfo>
    </xsl:template>

    <xsl:template match="ead:unitdate/@normal">
        <xsl:variable name="startDate">
            <xsl:value-of
                    select="
                    if (contains(., '/')) then
                        substring-before(., '/')
                    else
                        ."
                    />
        </xsl:variable>
        <xsl:variable name="endDate">
            <xsl:value-of
                    select="
                    if (contains(., '/')) then
                        substring-after(., '/')
                    else
                        ."
                    />
        </xsl:variable>
        <!--these next variables assume and trust that the data is encoded like so:
            1900-10-02, which is what ASpace does.

           if people hand-enter data, though, i should check for the presence of hyphens.  iso8601 doesn't require those.
            -->
        <xsl:variable name="startYear">
            <xsl:value-of select="substring($startDate, 1, 4)"/>
        </xsl:variable>
        <xsl:variable name="startMonth">
            <xsl:value-of
                    select="
                    if (string-length($startDate) gt 4) then
                        substring($startDate, 6, 2)
                    else
                        '00'"
                    />
        </xsl:variable>
        <xsl:variable name="startDay">
            <xsl:value-of
                    select="
                    if (string-length($startDate) gt 8) then
                        substring($startDate, 9, 2)
                    else
                        '00'"
                    />
        </xsl:variable>
        <xsl:variable name="startTime">
            <xsl:value-of>
                <!-- this should suffice for analog materials.  need to test if ASpace can handle a full dateTime for digital material, though-->
                <xsl:text>T00:00:00Z</xsl:text>
            </xsl:value-of>
        </xsl:variable>

        <xsl:variable name="endYear">
            <xsl:value-of select="substring($endDate, 1, 4)"/>
        </xsl:variable>
        <xsl:variable name="endMonth">
            <xsl:value-of
                    select="
                    if (string-length($endDate) gt 4) then
                        substring($endDate, 6, 2)
                    else
                        '00'"
                    />
        </xsl:variable>
        <xsl:variable name="endDay">
            <xsl:value-of
                    select="
                    if (string-length($endDate) gt 8) then
                        substring($endDate, 9, 2)
                    else
                        '00'"
                    />
        </xsl:variable>
        <xsl:variable name="endTime">
            <xsl:value-of>
                <!-- this should suffice for analog materials.  need to test if ASpace can handle a full dateTime for digital material, though-->
                <xsl:text>T00:00:00Z</xsl:text>
            </xsl:value-of>
        </xsl:variable>

        <mods:dateOther>
            <xsl:attribute name="point">start</xsl:attribute>
            <xsl:attribute name="encoding">iso8601</xsl:attribute>
            <xsl:if
                    test="
                    not(../@type eq 'bulk') and not(../preceding-sibling::ead:unitdate[@type = ('single',
                    'inclusive')])">
                <xsl:attribute name="keyDate">yes</xsl:attribute>
            </xsl:if>
            <xsl:value-of
                    select="$startYear || '-' || $startMonth || '-' || $startDay || $startTime"/>
        </mods:dateOther>

        <!-- we won't tokenize bulk date ranges since those should always be repeated values.
            it would be nice, though, if we could weight the index in favor of bulk dates, I think...
            but right now, the only objective with this is to add a series of tokenized dates to support a
            date slider -->


        <xsl:if test="../@type = 'inclusive' and $paramertize-dates-option = true()">
            <xsl:call-template name="tokenize-dates">
                <xsl:with-param name="startYear" select="$startYear"/>
                <xsl:with-param name="endYear" select="$endYear"/>
            </xsl:call-template>
        </xsl:if>

        <!-- should we exclude this if the date end = date begin ?? -->
        <!-- should we exclude this if the date end = date begin ?? -->
        <!-- should we exclude this if the date end = date begin ?? -->

        <!-- should we exclude this if the date end = date begin ?? -->
        <!-- should we exclude this if the date end = date begin ?? -->
        <!-- should we exclude this if the date end = date begin ?? -->
        <mods:dateOther>
            <xsl:attribute name="point">end</xsl:attribute>
            <xsl:attribute name="encoding">iso8601</xsl:attribute>
            <xsl:value-of select="$endYear || '-' || $endMonth || '-' || $endDay || $endTime"/>
        </mods:dateOther>

    </xsl:template>


    <xsl:template name="tokenize-dates">
        <xsl:param name="startYear"/>
        <xsl:param name="endYear"/>
        <!-- what could go wrong here? :) -->
        <xsl:for-each select="(xs:integer($startYear) + 1) to (xs:integer($endYear) - 1)">
            <mods:dateOther>
                <xsl:attribute name="type">tokenized</xsl:attribute>
                <xsl:attribute name="encoding">iso8601</xsl:attribute>
                <xsl:value-of select=". || '-' || '00' || '-' || '00' || 'T00:00:00Z'"/>
            </mods:dateOther>
        </xsl:for-each>
    </xsl:template>



    <xsl:template match="ead:unitid">
        <mods:identifier type="ead-unitid">
            <xsl:value-of select="normalize-space()"/>
        </mods:identifier>
    </xsl:template>

    <xsl:template match="ead:eadid">
        <mods:identifier type="ead-eadid">
            <xsl:value-of select="normalize-space()"/>
        </mods:identifier>
    </xsl:template>

    <!-- with MODS 3.5, we can now separate extent units from extent numbers.  This aligns nicely with the AT, ASpace, and EAD3.
        example MODS encoding:
            <physicalDescription>
                <extent unit=”linear feet”>1.38</extent>
             </physicalDescription>
 -->
    <xsl:template match="ead:physdesc">
        <mods:physicalDescription>
            <xsl:apply-templates/>
        </mods:physicalDescription>
    </xsl:template>

    <xsl:template match="ead:extent">
        <mods:extent>
            <xsl:apply-templates/>
        </mods:extent>
    </xsl:template>

    <xsl:template match="ead:physfacet">
        <mods:note type="physfacet">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:dimensions">
        <mods:note type="dimensions">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>


    <xsl:template match="ead:origination">
        <mods:name>
            <mods:namePart>
                <xsl:apply-templates/>
            </mods:namePart>
        </mods:name>
    </xsl:template>

    <xsl:template match="ead:langmaterial/ead:language[@langcode]">
        <mods:language>
            <mods:languageTerm type="code" authority="iso639-2b">
                <xsl:value-of select="@langcode"/>
            </mods:languageTerm>
        </mods:language>
    </xsl:template>

    <xsl:template match="ead:langmaterial[@label]">
        <mods:note type="language" displayLabel="{@label}">
            <xsl:value-of select="."/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:langmaterial/ead:materialspec">
        <mods:note type="materialSpecificDetails">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:physloc">
        <mods:location>
            <mods:physicalLocation>
                <xsl:apply-templates/>
            </mods:physicalLocation>
        </mods:location>
    </xsl:template>

    <!--controlaccess stuff-->
    <xsl:template match="ead:controlaccess//ead:subject">
        <mods:subject>
            <mods:topic>
                <xsl:apply-templates/>
            </mods:topic>
        </mods:subject>
    </xsl:template>
    <xsl:template match="ead:controlaccess//ead:geogname">
        <mods:subject>
            <mods:geographic>
                <xsl:apply-templates/>
            </mods:geographic>
        </mods:subject>
    </xsl:template>
    <xsl:template match="ead:controlaccess//ead:genreform">
        <mods:subject>
            <mods:genre>
                <xsl:apply-templates/>
            </mods:genre>
        </mods:subject>
    </xsl:template>
    <xsl:template match="ead:controlaccess//ead:corpname">
        <mods:subject>
            <mods:name type="corporate">
                <mods:namePart>
                    <xsl:apply-templates/>
                </mods:namePart>
            </mods:name>
        </mods:subject>
    </xsl:template>
    <xsl:template match="ead:controlaccess//ead:persname | ead:controlaccess//ead:famname">
        <mods:subject>
            <mods:name type="personal">
                <mods:namePart>
                    <xsl:apply-templates/>
                </mods:namePart>
            </mods:name>
        </mods:subject>
    </xsl:template>
    <xsl:template match="ead:controlaccess//ead:title">
        <mods:subject>
            <mods:titleInfo>
                <mods:title>
                    <xsl:apply-templates/>
                </mods:title>
            </mods:titleInfo>
        </mods:subject>
    </xsl:template>
    <xsl:template match="ead:controlaccess//ead:function">
        <mods:subject displayLabel="function">
            <mods:topic>
                <xsl:apply-templates/>
            </mods:topic>
        </mods:subject>
    </xsl:template>
    <xsl:template match="ead:controlaccess//ead:occupation">
        <mods:subject>
            <mods:occupation>
                <xsl:apply-templates/>
            </mods:occupation>
        </mods:subject>
    </xsl:template>

    <xsl:template match="ead:accessrestrict | ead:userestrict">
        <mods:accessCondition>
            <xsl:attribute name="type"
                           select="
                    if (self::ead:accessrestrict) then
                        'restrictionOnAccess'
                    else
                        'useAndReproduction'"/>
            <xsl:apply-templates/>
        </mods:accessCondition>
    </xsl:template>

    <xsl:template match="ead:accurals">
        <mods:note type="accuralMethod">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:acqinfo">
        <mods:note type="acquistion">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:altformavail">
        <mods:note type="additionalForm">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <!-- this does not allow roundtripping of the data, obviously, but it follows the DLF Aquifer guidelines -->
    <xsl:template match="ead:appraisal | ead:processinfo">
        <mods:note type="action">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:arrangement">
        <mods:note type="organization">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:bibliography">
        <mods:note type="bibliography">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:bioghist">
        <mods:note type="biographical/historical">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:custodhist">
        <mods:note type="owernship">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <!-- not in use in our AT/ASpace databases; added here for completeness -->
    <xsl:template match="ead:fileplan">
        <mods:note type="fileplan">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:index">
        <mods:note type="index">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <!-- this is the only note that doesn't receive a type attribute.  we could easily change this, though, if desired.
        additionally... if it's important to retain that all of these notes are from EAD source files, we could just give them a type of
        ead-{node-name-in-EAD} -->
    <xsl:template match="ead:odd | ead:note">
        <mods:note>
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:originalsloc">
        <mods:note type="originalsLocation">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:otherfindingaid">
        <mods:note type="otherFindingAid">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:phystech">
        <mods:note type="sourceCharacteristics">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:prefercite">
        <mods:note type="preferredCitation">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:relatedmaterial">
        <mods:note type="relatedMaterial">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>

    <xsl:template match="ead:separatedmaterial">
        <mods:note type="separatedMaterial">
            <xsl:apply-templates/>
        </mods:note>
    </xsl:template>



    <!-- SECTION 4 -->
    <!-- SECTION 4 -->
    <!-- SECTION 4 -->
    <xsl:template
            match="ead:c | ead:c01 | ead:c02 | ead:c03 | ead:c04 | ead:c05 | ead:c06 | ead:c07 | ead:c08 | ead:c09 | ead:c10 | ead:c11 | ead:c12"
            mode="treeData">
        <xsl:variable name="data-dao-self"
                      select="
                if (ead:dao) then
                    true()
                else
                    false()"/>
        <xsl:choose>
            <xsl:when
                    test="ead:c | ead:c02 | ead:c03 | ead:c04 | ead:c05 | ead:c06 | ead:c07 | ead:c08 | ead:c09 | ead:c10 | ead:c11 | ead:c12">
                <li>
                    <xsl:if test="@level">
                        <xsl:attribute name="class" select="@level"/>
                    </xsl:if>
                    <xsl:if test="$data-dao-self eq true()">
                        <xsl:attribute name="data-dao-self" select="$data-dao-self"/>
                    </xsl:if>
                    <xsl:call-template name="construct-title-for-context-tree"/>
                    <ul>
                        <!--if there is child other than the initial did, then we'll need to call this template recursively, like so-->
                        <xsl:apply-templates mode="#current"
                                             select="ead:c | ead:c02 | ead:c03 | ead:c04 | ead:c05 | ead:c06 | ead:c07 | ead:c08 | ead:c09 | ead:c10 | ead:c11 | ead:c12"
                                />
                    </ul>
                </li>
            </xsl:when>
            <xsl:otherwise>
                <li class="{@level}">
                    <xsl:if test="$data-dao-self eq true()">
                        <xsl:attribute name="data-dao-self" select="$data-dao-self"/>
                    </xsl:if>
                    <xsl:call-template name="construct-title-for-context-tree"/>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="construct-title-for-HTML">
        <xsl:choose>
            <xsl:when test="ead:unittitle/normalize-space() eq '' or empty(ead:unittitle)">
                <xsl:apply-templates
                        select="../ancestor::*[ead:did/ead:unittitle/normalize-space() ne ''][1]/ead:did/ead:unittitle"
                        mode="HTML-title"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="ead:unittitle" mode="HTML-title"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="construct-title-for-context-tree">
        <xsl:param name="from-treeData-mode" select="false()" as="xs:boolean"/>
        <a>
            <xsl:attribute name="id">
                <xsl:value-of select="concat($collection-ID, '/', @id)"/>
            </xsl:attribute>
            <!-- i might need to update this to look out for trailinng punctuation arleady part of the unitid -->
            <xsl:if test="ead:did/ead:unitid and contains(@level, 'series')">
                <xsl:apply-templates select="ead:did/ead:unitid" mode="#current"/>
                <xsl:text>: </xsl:text>
            </xsl:if>
            <xsl:call-template name="combine-that-title-and-date-HTML">
                <xsl:with-param name="from-treeData-mode" select="true()" as="xs:boolean"/>
            </xsl:call-template>
        </a>
    </xsl:template>

    <xsl:template name="combine-that-title-and-date-NO-HTML">
        <xsl:param name="xpath" select="ead:did"/>
        <xsl:param name="from-treeData-mode" select="false()" as="xs:boolean"/>
        <!--need to test if the trailing-quote modes work as expected still!!!!-->
        <xsl:choose>
            <!--this 1st when test determines whether the template is called at the collection-level
            or elsewhere-->
            <xsl:when test="$xpath is /ead:ead/ead:archdesc[1]/ead:did[1]">
                <!-- (no need to test if there's a unitdate, since it is required by the AT at the collection-level)-->
                <xsl:choose>
                    <xsl:when test="ends-with(normalize-space($xpath/ead:unittitle), '&quot;')">
                        <xsl:apply-templates select="$xpath/ead:unittitle" mode="trailing-quote"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$xpath/ead:unittitle" mode="text-only"/>
                        <xsl:text>, </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <!--prepare the date(s)-->
                <xsl:apply-templates
                        select="$xpath/ead:unitdate[not(contains(., 'undated'))][not(@type = 'bulk')]"
                        mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
                <xsl:if
                        test="
                        $xpath/ead:unitdate[preceding-sibling::ead:unitdate][(contains(., 'undated'))] or
                        $xpath/ead:unitdate[following-sibling::ead:unitdate][(contains(., 'undated'))]">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:apply-templates select="$xpath/ead:unitdate[(contains(., 'undated'))]"
                                     mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="$xpath/ead:unitdate[@type = 'bulk']"
                                     mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <!--test if the unittitle is NOT empty, which will be most cases-->
                <xsl:if test="$xpath/ead:unittitle/normalize-space(.) ne ''">
                    <!--pass it on to the unittitle template-->
                    <xsl:choose>
                        <xsl:when test="ends-with(normalize-space($xpath/ead:unittitle), '&quot;')">
                            <xsl:choose>
                                <xsl:when
                                        test="
                                        $from-treeData-mode eq true() and
                                        not($xpath/ead:unitdate)">
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="trailing-quote">
                                        <xsl:with-param name="keep-existing-comma" select="false()"
                                                        as="xs:boolean"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:when test="$from-treeData-mode eq true()">
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="trailing-quote"/>
                                </xsl:when>
                                <xsl:when test="$xpath/ead:unitdate">
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="trailing-quote">
                                        <xsl:with-param name="keep-existing-comma" select="false()"
                                                        as="xs:boolean"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="trailing-quote"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when
                                test="
                                $xpath/ead:unittitle/*[last()][@render = 'doublequote' or @render = 'singlequote' or
                                @render = 'bolddoublequote' or @render = 'boldsinglequote']">
                            <xsl:choose>
                                <xsl:when test="$xpath/ead:unitdate">
                                    <xsl:apply-templates select="$xpath/ead:unittitle">
                                        <xsl:with-param name="add-comma" select="true()"
                                                        as="xs:boolean"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="text-only"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$xpath/ead:unittitle" mode="text-only"/>
                            <!-- here, unitdates aren't required by the AT, so we need to test if one
                                exists before adding the first comma-->
                            <xsl:if test="$xpath/ead:unitdate">
                                <xsl:text>, </xsl:text>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <!--the rest handles the unitdates...  if a title is missing, the unitdate
                    will thus just stand in for the unittitle-->
                <xsl:apply-templates
                        select="$xpath/ead:unitdate[not(contains(., 'undated'))][not(@type = 'bulk')]"
                        mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
                <xsl:if
                        test="
                        $xpath/ead:unitdate[preceding-sibling::ead:unitdate][(contains(., 'undated'))] or
                        $xpath/ead:unitdate[following-sibling::ead:unitdate][(contains(., 'undated'))]">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:apply-templates select="$xpath/ead:unitdate[(contains(., 'undated'))]"
                                     mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="$xpath/ead:unitdate[@type = 'bulk']"
                                     mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="combine-that-title-and-date-HTML">
        <xsl:param name="xpath" select="ead:did"/>
        <xsl:param name="from-treeData-mode" select="false()" as="xs:boolean"/>
        <!--need to test if the trailing-quote modes work as expected still!!!!-->
        <xsl:choose>
            <!--this 1st when test determines whether the template is called at the collection-level
            or elsewhere-->
            <xsl:when test="$xpath is /ead:ead/ead:archdesc[1]/ead:did[1]">
                <!-- (no need to test if there's a unitdate, since it is required by the AT at the collection-level)-->
                <xsl:choose>
                    <xsl:when test="ends-with(normalize-space($xpath/ead:unittitle), '&quot;')">
                        <xsl:apply-templates select="$xpath/ead:unittitle" mode="trailing-quote"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$xpath/ead:unittitle" mode="treeData"/>
                        <xsl:text>, </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <!--prepare the date(s)-->
                <xsl:apply-templates
                        select="$xpath/ead:unitdate[not(contains(., 'undated'))][not(@type = 'bulk')]"
                        mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
                <xsl:if
                        test="
                        $xpath/ead:unitdate[preceding-sibling::ead:unitdate][(contains(., 'undated'))] or
                        $xpath/ead:unitdate[following-sibling::ead:unitdate][(contains(., 'undated'))]">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:apply-templates select="$xpath/ead:unitdate[(contains(., 'undated'))]"
                                     mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="$xpath/ead:unitdate[@type = 'bulk']"
                                     mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <!--test if the unittitle is NOT empty, which will be most cases-->
                <xsl:if test="$xpath/ead:unittitle/normalize-space(.) ne ''">
                    <!--pass it on to the unittitle template-->
                    <xsl:choose>
                        <xsl:when test="ends-with(normalize-space($xpath/ead:unittitle), '&quot;')">
                            <xsl:choose>
                                <xsl:when
                                        test="
                                        $from-treeData-mode eq true() and
                                        not($xpath/ead:unitdate)">
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="trailing-quote">
                                        <xsl:with-param name="keep-existing-comma" select="false()"
                                                        as="xs:boolean"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:when test="$from-treeData-mode eq true()">
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="trailing-quote"/>
                                </xsl:when>
                                <xsl:when test="$xpath/ead:unitdate">
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="trailing-quote">
                                        <xsl:with-param name="keep-existing-comma" select="false()"
                                                        as="xs:boolean"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="trailing-quote"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when
                                test="
                                $xpath/ead:unittitle/*[last()][@render = 'doublequote' or @render = 'singlequote' or
                                @render = 'bolddoublequote' or @render = 'boldsinglequote']">
                            <xsl:choose>
                                <xsl:when test="$xpath/ead:unitdate">
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="treeData">
                                        <xsl:with-param name="add-comma" select="true()"
                                                        as="xs:boolean"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="$xpath/ead:unittitle"
                                                         mode="treeData"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$xpath/ead:unittitle" mode="treeData"/>
                            <!-- here, unitdates aren't required by the AT, so we need to test if one
                                exists before adding the first comma-->
                            <xsl:if test="$xpath/ead:unitdate">
                                <xsl:text>, </xsl:text>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <!--the rest handles the unitdates...  if a title is missing, the unitdate
                    will thus just stand in for the unittitle-->
                <xsl:apply-templates
                        select="$xpath/ead:unitdate[not(contains(., 'undated'))][not(@type = 'bulk')]"
                        mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
                <xsl:if
                        test="
                        $xpath/ead:unitdate[preceding-sibling::ead:unitdate][(contains(., 'undated'))] or
                        $xpath/ead:unitdate[following-sibling::ead:unitdate][(contains(., 'undated'))]">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:apply-templates select="$xpath/ead:unitdate[(contains(., 'undated'))]"
                                     mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="$xpath/ead:unitdate[@type = 'bulk']"
                                     mode="date-title-combine">
                    <xsl:sort select="substring-before(@normal, '/')" data-type="number"/>
                    <xsl:sort select="substring-after(@normal, '/')" data-type="number"/>
                    <xsl:sort select="." data-type="text" order="ascending"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="ead:unitdate[not(@type = 'bulk')]" mode="date-title-combine">
        <xsl:apply-templates/>
        <xsl:if test="not(position() = last())">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="ead:unitdate[@type = 'bulk']" mode="date-title-combine">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates/>
        <xsl:if test="not(position() = last())">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:text>)</xsl:text>
    </xsl:template>



    <!-- mode=treeData for HTML display purposes (should probably be renamed HTML display) -->
    <xsl:template match="*[@render = 'bold']" mode="treeData">
        <strong>
            <xsl:apply-templates/>
        </strong>
    </xsl:template>

    <xsl:template match="*[@render = 'bolddoublequote']" mode="treeData">
        <xsl:param name="add-comma" select="false()" as="xs:boolean"/>
        <strong>
            <xsl:choose>
                <xsl:when test="$add-comma eq true()"> &#x201c;<xsl:apply-templates/>,&#x201d; </xsl:when>
                <xsl:otherwise> &#x201c;<xsl:apply-templates/>&#x201d; </xsl:otherwise>
            </xsl:choose>
        </strong>
    </xsl:template>

    <xsl:template match="*[@render = 'boldsinglequote']" mode="treeData">
        <xsl:param name="add-comma" select="false()" as="xs:boolean"/>
        <strong>
            <xsl:choose>
                <xsl:when test="$add-comma eq true()"> &#x2018;<xsl:apply-templates/>,&#x2019; </xsl:when>
                <xsl:otherwise> &#x2018;<xsl:apply-templates/>&#x2019; </xsl:otherwise>
            </xsl:choose>
        </strong>
    </xsl:template>

    <xsl:template match="*[@render = 'bolditalic']" mode="treeData">
        <strong>
            <em>
                <xsl:apply-templates/>
            </em>
        </strong>
    </xsl:template>
    <xsl:template match="*[@render = 'boldsmcaps']" mode="treeData">
        <strong>
            <span class="smcaps">
                <xsl:apply-templates/>
            </span>
        </strong>
    </xsl:template>
    <xsl:template match="*[@render = 'boldunderline']" mode="treeData">
        <strong>
            <span class="underline">
                <xsl:apply-templates/>
            </span>
        </strong>
    </xsl:template>

    <xsl:template match="*[@render = 'italic']" mode="treeData">
        <em>
            <xsl:apply-templates/>
        </em>
    </xsl:template>

    <xsl:template match="*[@render = 'smcaps']" mode="treeData">
        <span class="smcaps">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="*[@render = 'sub']" mode="treeData">
        <sub>
            <xsl:apply-templates/>
        </sub>
    </xsl:template>
    <xsl:template match="*[@render = 'super']" mode="treeData">
        <sup>
            <xsl:apply-templates/>
        </sup>
    </xsl:template>
    <xsl:template match="*[@render = 'underline']" mode="treeData">
        <span class="underline">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="*[@render = 'doublequote']" mode="#all">
        <xsl:param name="add-comma" select="false()" as="xs:boolean"/>
        <xsl:choose>
            <xsl:when test="$add-comma eq true()"> &#x201c;<xsl:apply-templates/>,&#x201d; </xsl:when>
            <xsl:otherwise> &#x201c;<xsl:apply-templates/>&#x201d; </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[@render = 'singlequote']" mode="#all">
        <xsl:param name="add-comma" select="false()" as="xs:boolean"/>
        <xsl:choose>
            <xsl:when test="$add-comma eq true()"> &#x2018;<xsl:apply-templates/>,&#x2019; </xsl:when>
            <xsl:otherwise> &#x2018;<xsl:apply-templates/>&#x2019; </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- temporary patch (will fix later on) -->
    <xsl:template match="*[@render = 'bold']" mode="HTML-title">
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <strong>
            <xsl:apply-templates/>
        </strong>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="*[@render = 'bolddoublequote']" mode="HTML-title">
        <xsl:param name="add-comma" select="false()" as="xs:boolean"/>
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <strong>
            <xsl:choose>
                <xsl:when test="$add-comma eq true()"> &#x201c;<xsl:apply-templates/>,&#x201d; </xsl:when>
                <xsl:otherwise> &#x201c;<xsl:apply-templates/>&#x201d; </xsl:otherwise>
            </xsl:choose>
        </strong>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="*[@render = 'boldsinglequote']" mode="HTML-title">
        <xsl:param name="add-comma" select="false()" as="xs:boolean"/>
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <strong>
            <xsl:choose>
                <xsl:when test="$add-comma eq true()"> &#x2018;<xsl:apply-templates/>,&#x2019; </xsl:when>
                <xsl:otherwise> &#x2018;<xsl:apply-templates/>&#x2019; </xsl:otherwise>
            </xsl:choose>
        </strong>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="*[@render = 'bolditalic']">
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <strong>
            <em>
                <xsl:apply-templates/>
            </em>
        </strong>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="*[@render = 'boldsmcaps']">
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <strong>
            <span class="smcaps">
                <xsl:apply-templates/>
            </span>
        </strong>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="*[@render = 'boldunderline']">
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <strong>
            <span class="underline">
                <xsl:apply-templates/>
            </span>
        </strong>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="*[@render = 'italic']" mode="HTML-title">
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <em>
            <xsl:apply-templates/>
        </em>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="*[@render = 'smcaps']" mode="HTML-title">
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <span class="smcaps">
            <xsl:apply-templates/>
        </span>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="*[@render = 'sub']" mode="HTML-title">
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <sub>
            <xsl:apply-templates/>
        </sub>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="*[@render = 'super']" mode="HTML-title">
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <sup>
            <xsl:apply-templates/>
        </sup>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="*[@render = 'underline']" mode="HTML-title">
        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
        <span class="underline">
            <xsl:apply-templates/>
        </span>
        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </xsl:template>


    <xsl:template match="ead:unittitle/text()[last()]" mode="trailing-quote">
        <xsl:param name="keep-existing-comma" select="true()" as="xs:boolean"/>
        <xsl:choose>
            <xsl:when test="$keep-existing-comma eq false()">
                <xsl:value-of select="replace(., ',&quot;$', '&quot;')"/>
            </xsl:when>
            <xsl:when test="ends-with(., ',&quot;')">
                <xsl:value-of select="concat(., ' ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="replace(., '&quot;$', ',&quot; ')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>