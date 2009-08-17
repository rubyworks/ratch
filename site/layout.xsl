<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output cdata-section-elements="script"/>

  <xsl:template match="/">

    <html>
    <head>
      <title>Ratch</title>

      <link href="styles/style.css" rel="stylesheet" type="text/css"/>
      <link href="images/ratch-sm.png" rel="shortcut icon"/>

      <script type="text/javascript" src="js/jquery.js"></script>
      <script type="text/javascript">
        $(document).ready(function(){
        });
      </script>
    </head>

    <body>

    <iframe id="tigerops" src="http://tigerops.org/sidebar.html"/>

    <div class="menu">
      <a href="index.xml">What's Up</a> &#x00B7;
      <a href="started.xml">Getting Started</a> &#x00B7;
      <!--<a href="tutorial.xml">Tutorial</a> &#x00B7;-->
      <a href="api/index.html">Documentation</a> &#x00B7;
      <!-- <a href="">Mailing List</a> &#x00B7; -->
      <a href="http://rubyforge.org/projects/ratch">Development</a>
    </div>

    <div class="container">

      <div class="banner">
        <img src="images/ratch-sm.png" align="right"/>
        <span class="title1">RATCH</span><br/>
        <span class="title2">Ruby-based Batch Scripting</span>
        <!-- <img src="images/ratch-bg.png" style="margin: -72px -80px 0px 0px;" align="right"/> -->
        <!-- <img src="img/red-ratch2.jpg" style="margin-top: -110px; margin-left: -600px; padding-bottom: 10px;"/> -->
      </div>

      <div class="content textile">
        <xsl:apply-templates />
      </div>

      <div class="copyright" style="clear: both;">
        <b>Ratch</b>, Copyright &#x00A9; 2007 Tiger Ops (sponsered by <a href="http://psytower.info">&#x3a8; &#x3a4; Corp.</a>)
        Website design by <a href="http://psytower.info/transcode/">Trans</a> using XSL/XSLT.
      </div>

    </div>

    </body>
    </html>

  </xsl:template>

  <xsl:template match="content">
    <xsl:copy-of select="."/>
  </xsl:template>

</xsl:stylesheet>

