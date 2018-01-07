<?xml version="1.0" encoding="UTF-8"?>
<!-- Yale University Library XSLT Stylesheet ::
  Transform ArchivesSpace EAD output to be EAD compliant with Yale's EAD best practice guidelines

  maintained by: mark.custer@yale.edu

  this file uses the yale.at2yalebpgs.xsl stylesheet, which is maintained by michael.rush@yale.edu, as its foundation.

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ead="urn:isbn:1-931666-22-9"
                xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mdc="http://www.local-functions/mdc"
                exclude-result-prefixes="xsl ead mdc xsi" xpath-default-namespace="urn:isbn:1-931666-22-9"
                version="2.0">

    <xsl:output method="xml" indent="no" encoding="UTF-8" omit-xml-declaration="no"/>

    <xsl:function name="mdc:iso-date-2-display-form" as="xs:string*">
        <xsl:param name="date" as="xs:string"/>
        <xsl:variable name="months"
                      select="
        ('January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December')"/>
        <xsl:analyze-string select="$date" flags="x" regex="(\d{{4}})(\d{{2}})?(\d{{2}})?">
            <xsl:matching-substring>
                <!-- year -->
                <xsl:value-of select="regex-group(1)"/>
                <!-- month (can't add an if,then,else '' statement here without getting an extra space at the end of the result-->
                <xsl:if test="regex-group(2)">
                    <xsl:value-of select="subsequence($months, number(regex-group(2)), 1)"/>
                </xsl:if>
                <!-- day -->
                <xsl:if test="regex-group(3)">
                    <xsl:number value="regex-group(3)" format="1"/>
                </xsl:if>
                <!-- still need to handle time... but if that's there, then I can just use xs:dateTime !!!! -->
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>

    <!-- Name of the stylesheet. -->
    <xsl:param name="xslName">yale.aspace2yalebpgs.xsl</xsl:param>

    <!-- Describes what this stylesheet does. -->
    <xsl:param name="changeDesc">Transforms ArchivesSpace EAD export so that it complies with the Yale
        EAD Best Practice Guidelines.</xsl:param>

    <xsl:include href="http://www.library.yale.edu/facc/xsl/include/yale.ead2002.id_head_values.xsl"/>

    <!-- Repository Parameter -->
    <xsl:param name="repository">
        <xsl:value-of select="substring-before(normalize-space(/ead:ead/ead:eadheader/ead:eadid), '.')"
                />
    </xsl:param>

    <!-- Repository Code -->
    <xsl:param name="repository_code">
        <xsl:choose>
            <!-- MSSA choice -->
            <xsl:when test="$repository = 'mssa'">
                <xsl:text>US-CtY</xsl:text>
            </xsl:when>
            <!-- BRBL choice -->
            <xsl:when test="$repository = 'beinecke'">
                <xsl:text>US-CtY-BR</xsl:text>
            </xsl:when>
            <!-- Divinity choice -->
            <xsl:when test="$repository = 'divinity'">
                <xsl:text>US-CtY-D</xsl:text>
            </xsl:when>
            <!-- Music choice -->
            <xsl:when test="$repository = 'music'">
                <xsl:text>US-CtY-Mus</xsl:text>
            </xsl:when>
            <!-- Medical choice -->
            <xsl:when test="$repository = 'med'">
                <xsl:text>US-CtY-M</xsl:text>
            </xsl:when>
            <!-- Arts choice -->
            <xsl:when test="$repository = 'arts'">
                <xsl:text>US-CtY-A</xsl:text>
            </xsl:when>
            <!-- VRC choice -->
            <xsl:when test="$repository = 'vrc'">
                <xsl:text>US-CtY-A</xsl:text>
            </xsl:when>
            <!-- YCBA choice -->
            <xsl:when test="$repository = 'ycba'">
                <xsl:text>US-CtY-BA</xsl:text>
            </xsl:when>
            <!-- Walpole choice -->
            <xsl:when test="$repository = 'lwl'">
                <xsl:text>US-CtY-LWL</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>US-CtY</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:param>


    <!--MDC:  changed the previous template to the standard identity template -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*/text()[normalize-space()]">
        <xsl:value-of select="replace(., '\n|\s+', ' ')"/>
    </xsl:template>

    <xsl:template match="*/text()[not(normalize-space())]"/>


    <!-- this won't work if there are multiple change elements that were imported into the AT.  in that case, the XML
      will NOT be well formed upon export. since the ASpace data model has changed for that, let's consider the new model
    when deciding what to do in the meantime.-->
    <xsl:template match="ead:revisiondesc[not(ead:change)]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="change" namespace="urn:isbn:1-931666-22-9">
                <xsl:apply-templates select="node()"/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@id[starts-with(., 'aspace_ref')]">
        <xsl:attribute name="id">
            <xsl:value-of select="substring-after(., 'aspace_')"/>
        </xsl:attribute>
    </xsl:template>

    <!-- MDC:  new additions for new data-entry rules in ArchivesSpace !!! -->
    <xsl:template match="ead:*[@level = 'series']/ead:did/ead:unitid[matches(., '^\d+$')]">
        <xsl:variable name="roman-numeral">
            <xsl:number value="." format="I"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="concat('Series ', $roman-numeral)"/>
        </xsl:copy>
    </xsl:template>

    <!--optimized for what ASpace can output (up to 2 extents only).  If these templates are not used with AS-produced EAD, they
      will definitely need to change!-->
    <xsl:template match="ead:extent[1][matches(., '^\d')]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!--ASpace doesn't force the extent number to be a number, so we'll need to validate and test this on our own-->
            <xsl:variable name="extent-number" select="number(substring-before(normalize-space(.), ' '))"/>
            <xsl:variable name="extent-type" select="lower-case(substring-after(normalize-space(.), ' '))"/>
            <xsl:value-of select="format-number($extent-number, '#,###')"/>
            <xsl:text> </xsl:text>
            <xsl:choose>
                <!--changes feet to foot for singular extents-->
                <xsl:when test="$extent-number eq 1 and contains($extent-type, ' feet')">
                    <xsl:value-of select="replace($extent-type, ' feet', ' foot')"/>
                </xsl:when>
                <!--changes boxes to box for singular extents-->
                <xsl:when test="$extent-number eq 1 and contains($extent-type, ' Boxes')">
                    <xsl:value-of select="replace($extent-type, ' Boxes', ' Box')"/>
                </xsl:when>
                <!--changes works to work for the "Works of art" extent type, if this is used-->
                <xsl:when test="$extent-number eq 1 and contains($extent-type, ' Works of art')">
                    <xsl:value-of select="replace($extent-type, ' Works', ' Work')"/>
                </xsl:when>
                <!--chops off the trailing 's' for singular extents-->
                <xsl:when test="$extent-number eq 1 and ends-with($extent-type, 's')">
                    <xsl:variable name="sl" select="string-length($extent-type)"/>
                    <xsl:value-of select="substring($extent-type, 1, $sl - 1)"/>
                </xsl:when>
                <!--chops off the trailing 's' for singular extents that are in AAT form, with a paranthetical qualifer-->
                <xsl:when test="$extent-number eq 1 and ends-with($extent-type, ')')">
                    <xsl:value-of select="replace($extent-type, 's \(', ' (')"/>
                </xsl:when>
                <!--any other irregular singluar/plural extent type names???-->

                <!--otherwise, just print out the childless text node as is-->
                <xsl:otherwise>
                    <xsl:value-of select="$extent-type"/>
                </xsl:otherwise>

            </xsl:choose>

            <!--provide a separator before the next extent value, if present-->
            <xsl:choose>
                <!-- if there's a second extent, and that value starts with an open parentheis character, then add a space-->
                <xsl:when test="starts-with(following-sibling::ead:extent[1], '(')">
                    <xsl:text> </xsl:text>
                </xsl:when>
                <!--otherwise, if there's a second extent value, add a comma and a space-->
                <xsl:when test="following-sibling::ead:extent[1]">
                    <xsl:text>, </xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <!-- this stuff won't work for all of the hand-encoded YCBA files, so those should probably be updated in ASpace.
      Or, just remove these templates for YCBA by adding a repository-based filter-->
    <xsl:template match="ead:physfacet">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="preceding-sibling::ead:extent">
                    <xsl:text> : </xsl:text>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="ead:dimensions">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="preceding-sibling::ead:extent | preceding-sibling::ead:physfacet">
                    <xsl:text> ; </xsl:text>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>


    <!-- silly hack to deal with the fact that ASpace won't allow notes over 65k.
      might want to try this with for-each-group instead.
      remove when no longer necessary-->
    <xsl:template match="ead:*[matches(ead:head, '^\d\)')][1]" priority="2">
        <xsl:variable name="grouping-element-name" select="local-name()"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="substring-after(ead:head, ') ')"/>
            </xsl:element>
            <xsl:apply-templates select="ead:* except ead:head"/>
            <xsl:apply-templates
                    select="../ead:*[local-name() = $grouping-element-name][matches(ead:head, '^\d\)')][position() gt 1]/ead:*[not(local-name() = 'head')]"
                    />
        </xsl:copy>
    </xsl:template>
    <xsl:template match="ead:*[matches(ead:head, '^\d\)')][position() gt 1]" priority="2"/>

    <!-- everything from the AT to BPG file, with a few changes, specifically for how to handle dates -->
    <!-- everything from the AT to BPG file, with a few changes, specifically for how to handle dates -->
    <!-- everything from the AT to BPG file, with a few changes, specifically for how to handle dates -->
    <xsl:template match="ead:ead">
        <xsl:copy>
            <xsl:copy-of select="@*[not(local-name() = 'id') and not(local-name() = 'schemaLocation')]"/>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>urn:isbn:1-931666-22-9 http://www.library.yale.edu/facc/schemas/ead/ead.xsd</xsl:text>
            </xsl:attribute>
            <xsl:if test="ead:eadheader/ead:eadid[normalize-space()]">
                <xsl:attribute name="id">
                    <xsl:value-of select="replace(ead:eadheader/ead:eadid, '\s', '')"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:eadheader" priority="2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="audience">
                <xsl:text>internal</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="scriptencoding">
                <xsl:text>iso15924</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:filedesc">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
            <xsl:if test="not(ead:notestmt)">
                <xsl:element name="notestmt" namespace="urn:isbn:1-931666-22-9">
                    <xsl:element name="note" namespace="urn:isbn:1-931666-22-9">
                        <xsl:attribute name="type">
                            <xsl:text>bpg</xsl:text>
                        </xsl:attribute>
                        <xsl:element name="p" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>This encoded finding aid is compliant with the Yale EAD Best Practice Guidelines, Version 1.0.</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:element>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:eadid">
        <xsl:copy>
            <xsl:attribute name="countrycode">
                <xsl:text>US</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="mainagencycode">
                <xsl:value-of select="$repository_code"/>
            </xsl:attribute>
            <xsl:attribute name="publicid">
                <xsl:text>-//Yale University::</xsl:text>
                <xsl:value-of select="normalize-space(/ead//archdesc/did/repository/corpname)"/>
                <xsl:text>//TEXT (US::</xsl:text>
                <xsl:value-of select="substring-after($repository_code, '-')"/>
                <xsl:text>::::[</xsl:text>
                <xsl:value-of
                        select="translate(normalize-space(/ead//archdesc/did/unittitle[1]), '&quot;', '')"/>
                <xsl:text>])//EN</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="url">
                <xsl:value-of select="concat('http://hdl.handle.net/10079/fa/', normalize-space(.))"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <!-- added on 2013-03-01 (MDC).  -->
    <xsl:template match="ead:titlestmt">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates
                    select="
          ead:titleproper[not(@type = 'filing')],
          ead:titleproper[@type = 'filing'],
          ead:subtitle,
          ead:author,
          ead:sponsor"/>
            <!-- if the author field is empty in ASpace for a Beinecke finding aid, the style sheet will add "by Beinecke staff"-->
            <xsl:if test="not(exists(ead:author)) and $repository = 'beinecke'">
                <xsl:element name="author" namespace="urn:isbn:1-931666-22-9">
                    <xsl:text>by Beinecke staff</xsl:text>
                </xsl:element>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:titleproper[not(@type)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="type">
                <xsl:text>formal</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:titleproper[@type = 'filing']">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="audience">
                <xsl:text>internal</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:titleproper[not(@type)]/ead:num"/>

    <xsl:template match="ead:publicationstmt/ead:date" priority="1">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="not(@type)">
                <xsl:attribute name="type">
                    <xsl:text>original</xsl:text>
                </xsl:attribute>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:filedesc/ead:notestmt/ead:note">
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="contains(ead:p, 'Guidelines')">
                    <xsl:attribute name="type">
                        <xsl:text>bpg</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="type">
                        <xsl:text>frontmatter</xsl:text>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:profiledesc">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="ead:creation"/>
            <xsl:apply-templates select="ead:langusage"/>
            <xsl:if test="not(ead:langusage)">
                <xsl:element name="langusage" namespace="urn:isbn:1-931666-22-9">
                    <xsl:text>Finding aid written in </xsl:text>
                    <xsl:element name="language" namespace="urn:isbn:1-931666-22-9">
                        <xsl:attribute name="langcode">
                            <xsl:text>eng</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="scriptcode">
                            <xsl:text>Latn</xsl:text>
                        </xsl:attribute>
                        <xsl:text>English</xsl:text>
                    </xsl:element>
                </xsl:element>
            </xsl:if>
            <xsl:apply-templates select="ead:descrules"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:archdesc">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="relatedencoding">
                <xsl:text>MARC21</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="type">
                <xsl:text>register</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="ead:did"/>
            <xsl:if
                    test="
          ead:acqinfo | ead:custodhist | ead:accessrestrict | ead:legalstatus | ead:userestrict | ead:prefercite |
          ead:processinfo | ead:altformavail | ead:relatedmaterial | ead:separatedmaterial |
          ead:accruals | ead:appraisal | ead:originalsloc | ead:otherfindaid | ead:phystech |
          ead:fileplan | ead:bibliography">
                <xsl:element name="descgrp" namespace="urn:isbn:1-931666-22-9">
                    <xsl:attribute name="type">
                        <xsl:text>admininfo</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="id">
                        <xsl:value-of select="$admininfo_id"/>
                    </xsl:attribute>
                    <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                        <xsl:value-of select="$admininfo_head"/>
                    </xsl:element>
                    <xsl:if test="ead:acqinfo | ead:custodhist">
                        <xsl:element name="descgrp" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="type">
                                <xsl:text>provenance</xsl:text>
                            </xsl:attribute>
                            <xsl:attribute name="id">
                                <xsl:value-of select="$provenance_id"/>
                            </xsl:attribute>
                            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                                <xsl:value-of select="$provenance_head"/>
                            </xsl:element>
                            <xsl:apply-templates select="ead:acqinfo"/>
                            <xsl:apply-templates select="ead:custodhist"/>
                        </xsl:element>
                    </xsl:if>
                    <xsl:apply-templates select="ead:accessrestrict"/>
                    <xsl:apply-templates select="ead:legalstatus"/>
                    <xsl:apply-templates select="ead:userestrict"/>
                    <xsl:apply-templates select="ead:prefercite"/>
                    <xsl:apply-templates select="ead:processinfo"/>
                    <xsl:apply-templates select="ead:altformavail"/>
                    <xsl:apply-templates select="ead:relatedmaterial"/>
                    <xsl:apply-templates select="ead:separatedmaterial"/>
                    <xsl:apply-templates select="ead:accruals"/>
                    <xsl:apply-templates select="ead:appraisal"/>
                    <xsl:apply-templates select="ead:originalsloc"/>
                    <xsl:apply-templates select="ead:otherfindaid"/>
                    <xsl:apply-templates select="ead:phystech"/>
                    <xsl:apply-templates select="ead:fileplan"/>
                    <xsl:apply-templates select="ead:bibliography"/>
                </xsl:element>
            </xsl:if>
            <xsl:apply-templates select="ead:bioghist"/>
            <xsl:apply-templates select="ead:scopecontent"/>
            <xsl:apply-templates select="ead:arrangement"/>
            <xsl:apply-templates select="ead:controlaccess"/>
            <xsl:apply-templates select="ead:dsc"/>
            <xsl:apply-templates select="ead:odd"/>
            <xsl:apply-templates select="ead:index"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:archdesc/ead:did">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$did_head"/>
            </xsl:element>
            <xsl:apply-templates select="ead:unitid"/>
            <xsl:apply-templates select="ead:origination"/>
            <xsl:apply-templates select="ead:unittitle"/>
            <xsl:apply-templates select="ead:unitdate[@type = 'inclusive']"/>
            <xsl:apply-templates select="ead:unitdate[@type = 'bulk']"/>
            <xsl:apply-templates select="ead:unitdate[not(@type)]"/>
            <xsl:apply-templates select="ead:physdesc"/>
            <xsl:apply-templates select="ead:abstract"/>
            <xsl:apply-templates select="ead:langmaterial"/>
            <xsl:apply-templates select="ead:physloc"/>
            <xsl:apply-templates select="ead:materialspec"/>
            <xsl:apply-templates select="ead:note"/>
            <xsl:if test="$repository = 'mssa'">
                <xsl:apply-templates select="../ead:odd[starts-with(ead:p[1], 'Forms part of')]" mode="did"
                        />
            </xsl:if>
            <xsl:apply-templates select="ead:repository"/>
        </xsl:copy>
    </xsl:template>

    <!-- put all of this in ASpace and remove from here!!!!  -->
    <xsl:template match="ead:archdesc/ead:did/ead:repository">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$repository_label"/>
            </xsl:attribute>
            <xsl:choose>
                <!-- MSSA choice -->
                <xsl:when test="$repository = 'mssa'">
                    <xsl:element name="corpname" namespace="urn:isbn:1-931666-22-9">
                        <xsl:text>Manuscripts and Archives</xsl:text>
                    </xsl:element>
                    <xsl:element name="address" namespace="urn:isbn:1-931666-22-9">
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>Sterling Memorial Library</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>128 Wall Street</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>P.O. Box 208240</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>New Haven, CT 06520</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>web</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Web: http://web.library.yale.edu/mssa</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>email</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Email: mssa.assist@yale.edu</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>phone</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Phone: (203) 432-1735</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>fax</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Fax: (203) 432-7441</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <!-- BRBL choice -->
                <xsl:when test="$repository = 'beinecke'">
                    <xsl:element name="corpname" namespace="urn:isbn:1-931666-22-9">
                        <xsl:text>Beinecke Rare Book and Manuscript Library</xsl:text>
                    </xsl:element>
                    <xsl:element name="address" namespace="urn:isbn:1-931666-22-9">
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>P.O. Box 208330</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>New Haven, CT 06520</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>email</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Email: beinecke.library@yale.edu </xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>phone</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Phone: (203) 432-2972</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>fax</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Fax: (203) 432-4047</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <!-- Divinity choice -->
                <xsl:when test="$repository = 'divinity'">
                    <xsl:element name="corpname" namespace="urn:isbn:1-931666-22-9">
                        <xsl:text>Yale Divinity Library</xsl:text>
                    </xsl:element>
                    <xsl:element name="address" namespace="urn:isbn:1-931666-22-9">
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>409 Prospect Street</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>New Haven, CT 06511</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>email</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Email: divinity.library@yale.edu  </xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>phone</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Phone: 203 432-5301</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <!-- Music choice -->
                <xsl:when test="$repository = 'music'">
                    <xsl:element name="corpname" namespace="urn:isbn:1-931666-22-9">
                        <xsl:text>Irving S. Gilmore Music Library, Yale University</xsl:text>
                    </xsl:element>
                    <xsl:element name="address" namespace="urn:isbn:1-931666-22-9">
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>P.O. Box 208240</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>120 High Street</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>New Haven, CT 06520-8240</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>email</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Email: musiclibrary@yale.edu </xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>phone</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Phone:  (203) 432-0492</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>fax</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Fax: (203) 432-7339</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <!-- Medical choice -->
                <xsl:when test="$repository = 'med'">
                    <xsl:element name="corpname" namespace="urn:isbn:1-931666-22-9">
                        <xsl:text>Historical Library, Harvey Cushing / John Hay Whitney Medical Library</xsl:text>
                    </xsl:element>
                    <xsl:element name="address" namespace="urn:isbn:1-931666-22-9">
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>Yale University</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>333 Cedar St.</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>New Haven, CT 06520-8014</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>email</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Email: historical.library@yale.edu</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>phone</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Phone:  (203) 737-1192</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>fax</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Fax: (203) 785-5636</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <!-- Arts choice -->
                <xsl:when test="$repository = 'arts'">
                    <xsl:element name="corpname" namespace="urn:isbn:1-931666-22-9">
                        <xsl:text>Robert B. Haas Family Arts Library Special Collections</xsl:text>
                    </xsl:element>
                    <xsl:element name="address" namespace="urn:isbn:1-931666-22-9">
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>PO Box 208318</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>180 York Street</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>New Haven, CT 06520-8318</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>email</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Email: haasalsc@pantheon.yale.edu  </xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>phone</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Phone:  203.432-1712</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>fax</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Fax: 203.432-0549</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <!-- VRC choice -->
                <xsl:when test="$repository = 'vrc'">
                    <xsl:element name="corpname" namespace="urn:isbn:1-931666-22-9">
                        <xsl:text>Visual Resources Collection</xsl:text>
                    </xsl:element>
                    <xsl:element name="address" namespace="urn:isbn:1-931666-22-9">
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>Yale University Library</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>P.O. Box 208318</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>New Haven, CT 06520</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>phone</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Phone:  (203) 432-2443</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <!-- YCBA choice -->
                <xsl:when test="$repository = 'ycba'">
                    <xsl:element name="corpname" namespace="urn:isbn:1-931666-22-9">
                        <xsl:text>Yale Center for British Art</xsl:text>
                    </xsl:element>
                    <xsl:element name="address" namespace="urn:isbn:1-931666-22-9">
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>Department of Rare Books and Manuscripts</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>P.O. Box 208280</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>New Haven, CT, 06520-8280</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>email</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Email: ycba.rarebooks@yale.edu </xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>phone</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Phone:  203-432-2815</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <!-- Walpole choice -->
                <xsl:when test="$repository = 'lwl'">
                    <xsl:element name="corpname" namespace="urn:isbn:1-931666-22-9">
                        <xsl:text>The Lewis Walpole Library</xsl:text>
                    </xsl:element>
                    <xsl:element name="address" namespace="urn:isbn:1-931666-22-9">
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>154 Main Street</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>Farmington, CT 06032</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>email</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Email: walpole@yale.edu </xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>phone</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Phone: 860-677-2140</xsl:text>
                        </xsl:element>
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:attribute name="altrender">
                                <xsl:text>fax</xsl:text>
                            </xsl:attribute>
                            <xsl:text>Fax: 860-677-6369</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:when>
                <!-- Otherwise, supply generic YUL addressline -->
                <xsl:otherwise>
                    <xsl:element name="corpname" namespace="urn:isbn:1-931666-22-9">
                        <xsl:text>Yale University Library</xsl:text>
                    </xsl:element>
                    <xsl:element name="address" namespace="urn:isbn:1-931666-22-9">
                        <xsl:element name="addressline" namespace="urn:isbn:1-931666-22-9">
                            <xsl:text>New Haven, CT</xsl:text>
                        </xsl:element>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <!--add this to clean step for EAD to MODS -->
    <xsl:template match="ead:archdesc/ead:did/ead:unitid">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$unitid_label"/>
            </xsl:attribute>
            <xsl:attribute name="countrycode">
                <xsl:text>US</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="repositorycode">
                <xsl:value-of select="$repository_code"/>
            </xsl:attribute>
            <xsl:value-of select="translate(normalize-space(.), '.', ' ')"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:archdesc/ead:did/ead:origination">
        <xsl:copy>
            <xsl:copy-of select="@* except @label"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$origination_label"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:archdesc/ead:did/ead:origination[@label = 'source']"/>

    <xsl:template match="ead:archdesc/ead:did/ead:unittitle">
        <xsl:copy>
            <xsl:copy-of select="@* except @label"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$unittitle_label"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:unitdate[@type ne 'bulk'] | ead:unitdate[not(@type)]">
        <xsl:copy>
            <xsl:copy-of select="@* except @label"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$unitdate_label_inclusive"/>
            </xsl:attribute>
            <xsl:if test="not(@calendar)">
                <xsl:attribute name="calendar">
                    <xsl:text>gregorian</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="not(@era)">
                <xsl:attribute name="era">
                    <xsl:text>ce</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="not(@datechar)">
                <xsl:attribute name="datechar">
                    <xsl:text>creation</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <!-- example to deal with:
          <unitdate normal="1901-02/1951-04-28" type="inclusive">1901-02-1951-04-28</unitdate>
          <unitdate normal="2015-05-05/2015-05-05" type="inclusive">2015-05-05</unitdate>

          i'd like to use xs:date, but i can't use that on values like 2015-05, so I'll have to roll my own function for this?

          i also shouldn't create a new date string if the current text field contains any characters aside from spaces, hyphens, or numbers.
                    -->
            <xsl:choose>
                <xsl:when test="not(@normal) or matches(replace(., '/|-', ''), '[\D]')">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="first-date" select="replace(substring-before(@normal, '/'), '\D', '')"/>
                    <xsl:variable name="second-date" select="replace(substring-after(@normal, '/'), '\D', '')"/>
                    <!-- just adding the next line until i write a date conversion function-->
                    <xsl:value-of select="mdc:iso-date-2-display-form($first-date)"/>
                    <xsl:if test="$first-date ne $second-date">
                        <xsl:text> - </xsl:text>
                        <xsl:value-of select="mdc:iso-date-2-display-form($second-date)"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:unitdate[@type = 'bulk']">
        <xsl:copy>
            <xsl:copy-of select="@* except @label"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$unitdate_label_bulk"/>
            </xsl:attribute>
            <xsl:if test="not(@calendar)">
                <xsl:attribute name="calendar">
                    <xsl:text>gregorian</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="not(@era)">
                <xsl:attribute name="era">
                    <xsl:text>ce</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="not(@datechar)">
                <xsl:attribute name="datechar">
                    <xsl:text>creation</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <!-- need to convert these to human readable form if more granular than just a 4-digit year-->
                <xsl:when test="not(@normal) or matches(replace(., '/|-|bulk', ''), '[\D]')">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Bulk, </xsl:text>
                    <xsl:variable name="first-date" select="replace(substring-before(@normal, '/'), '\D', '')"/>
                    <xsl:variable name="second-date" select="replace(substring-after(@normal, '/'), '\D', '')"/>
                    <xsl:value-of select="mdc:iso-date-2-display-form($first-date)"/>
                    <xsl:if test="$first-date ne $second-date">
                        <xsl:text> - </xsl:text>
                        <xsl:value-of select="mdc:iso-date-2-display-form($second-date)"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:physdesc">
        <xsl:copy>
            <xsl:apply-templates select="@* except @label"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$physdesc_label"/>
            </xsl:attribute>
            <xsl:choose>
                <!-- hack for "0 See container summary" statements
                when ASpace removes this requuirement, we can remove this hack-->
                <xsl:when test="ead:extent[1][contains(., 'See Container Summary')]">
                    <xsl:apply-templates select="ead:extent[2]"/>
                </xsl:when>
                <xsl:when test="ead:extent[2]">
                    <xsl:for-each select="ead:extent[1]">
                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:apply-templates/>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="../ead:extent[2]"/>
                        </xsl:copy>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:langmaterial">
        <xsl:choose>
            <!-- mdc: this is bad, but since the kissinger finding aids have both a language code and a language note being
          exported by ArchivesSpacea as language ntoes, I'd like to remove the language note that doesn't have a textual description-->
            <xsl:when test="ead:language[not(contains(., ' '))] and ../ead:langmaterial[2]"/>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*[not(local-name()='id')]"/>
                    <xsl:attribute name="label">
                        <xsl:value-of select="$langmaterial_label"/>
                    </xsl:attribute>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="ead:abstract">
        <xsl:copy>
            <xsl:apply-templates select="@* except @label"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$abstract_label"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:physloc">
        <xsl:copy>
            <xsl:apply-templates select="@* except @label"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$physloc_label"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:materialspec">
        <xsl:copy>
            <xsl:apply-templates select="@* except @label"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$materialspec_label"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:note">
        <xsl:copy>
            <xsl:apply-templates select="@* except @label"/>
            <xsl:attribute name="label">
                <xsl:value-of select="$note_label"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:acqinfo[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:custodhist[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:accessrestrict[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$accessrestrict_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:userestrict[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$userestrict_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:prefercite[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$prefercite_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:processinfo[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$processinfo_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:altformavail[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$altformavail_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:relatedmaterial[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$relatedmaterial_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:separatedmaterial[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$separatedmaterial_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:accruals[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$accruals_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:appraisal[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$appraisal_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:originalsloc[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$originalsloc_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:otherfindaid[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$otherfindaid_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:phystech[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$phystech_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:fileplan[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$fileplan_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:bibliography[not(ancestor::ead:dsc)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$bibliography_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:archdesc/ead:controlaccess">
        <xsl:copy>
            <xsl:attribute name="id">
                <xsl:value-of select="$controlaccess_id"/>
            </xsl:attribute>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$controlaccess_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:archdesc/ead:odd">
        <xsl:choose>
            <xsl:when test="$repository = 'mssa' and starts-with(ead:p[1], 'Forms part of')"/>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:if test="not(@type)">
                        <xsl:attribute name="type">
                            <xsl:text>appendix</xsl:text>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:if test="not(ead:head)">
                        <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                            <xsl:value-of select="$odd_head"/>
                        </xsl:element>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="ead:archdesc/ead:odd" mode="did">
        <xsl:element name="note" namespace="urn:isbn:1-931666-22-9">
            <xsl:attribute name="label">
                <xsl:value-of select="$note_label"/>
            </xsl:attribute>
            <xsl:apply-templates select="ead:p"/>
        </xsl:element>
    </xsl:template>


    <xsl:template match="ead:archdesc/ead:dsc">
        <xsl:copy>
            <xsl:attribute name="type">
                <xsl:text>combined</xsl:text>
            </xsl:attribute>
            <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
                <xsl:value-of select="$dsc_head"/>
            </xsl:element>
            <xsl:apply-templates select="* except ead:head"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:dsc//ead:did">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="ead:container"/>
            <xsl:apply-templates select="ead:origination"/>
            <xsl:apply-templates select="ead:unitid"/>
            <xsl:apply-templates select="ead:unittitle"/>
            <xsl:apply-templates select="ead:unitdate[@type = 'inclusive'] | ead:unitdate[not(@type)]"/>
            <xsl:apply-templates select="ead:unitdate[@type = 'bulk']"/>
            <xsl:apply-templates select="ead:physdesc"/>
            <xsl:apply-templates select="ead:langmaterial"/>
            <xsl:apply-templates select="ead:materialspec"/>
            <xsl:apply-templates select="ead:physloc"/>
            <xsl:apply-templates select="ead:daogrp"/>
            <xsl:apply-templates select="ead:dao"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:container/@label">
        <xsl:attribute name="label">
            <xsl:value-of select="replace(., '\D', '')"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="ead:title">
        <xsl:copy>
            <xsl:copy-of select="@render"/>
            <xsl:if test="not(@render)">
                <xsl:attribute name="render">
                    <xsl:text>italic</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:attribute name="xlink:type">
                <xsl:text>simple</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:chronitem">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="ead:date"/>
            <xsl:choose>
                <xsl:when test="ead:eventgrp">
                    <xsl:apply-templates select="ead:eventgrp"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="eventgrp" namespace="urn:isbn:1-931666-22-9">
                        <xsl:apply-templates select="ead:event"/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>


    <!--addition by MDC-->
    <xsl:template match="ead:list[@type = 'ordered'][not(@numeration)]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="type">
                <xsl:text>simple</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@source">
        <xsl:attribute name="source">
            <xsl:choose>
                <xsl:when test=". = 'Library of Congress Subject Headings'">
                    <xsl:value-of select="'lcsh'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>

    <!-- hack to remove the duplicate elements exported by ArchivesSpace for creator + subject -->
    <xsl:template match="ead:controlaccess/*[. = preceding-sibling::*]"/>





</xsl:stylesheet>