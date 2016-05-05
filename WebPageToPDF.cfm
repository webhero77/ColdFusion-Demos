<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Page to PDF</title>
	<style>
		.form, .thumbsContainer
		{
			width: 90%;
			margin-left: auto;
			margin-right: auto;
			text-align:center;
			margin-bottom: 20px;		
		}
		
		.thumbsContainer
		{
			margin-top: 40px;
		}
		
		.thumbsContainer a, .thumbsContainer a:hover, .thumbsContainer a:visited, .thumbsContainer a:active
		{
			text-decoration: none;
			text-align: middle;
			vertical-align: top;
			color: #0099cc;
			
		}
		
		.thumbsContainer img
		{
			width: 90%;
		}
		
		.thumb
		{
			float: left;
			width: 17%;		
			padding: 5px 1px;
			margin: 5px;
			border-top: 1px solid #66ccff;
			border-bottom: 1px solid #0066cc;
			border-left: 1px solid #b3e7ff;
			border-right: 1px solid #0099cc;
		}	
		.errorMessage
		{	
			margin-top: 40px;
			color: #993333;
			font-weight: oblique;
			width: 100%;
			text-align: left;
		}
		
	</style>

	<cfscript>
		//working directory
		SUBDIR = "PdfDemo";
		//base path for working direcotry
		FILEPATH =  ExpandPath( "./" & SUBDIR & "/" );
		//WriteOutput(FILEPATH);	
		if (!DirectoryExists(FILEPATH))
		{
			DirectoryCreate(FILEPATH);
		}
		
		FINALURL = "";
		URLTITLE = "";
		PDFFILE = "";
		
		//shores up the supplied url to get pertinent info by calling helper methods
		function prepForPDF(rawURL)
		{
			resolveUrl(rawURL);
			URLTITLE = getTitle(FINALURL);
			PDFFILE = URLTITLE & ".pdf";
		
		}
		
		/*use a lighter version of cfhttp method to get the headers only and determine if this redirects and if so 
		to redirect to the referenced site in the responseHeader.Location
		in most cases a url without a subdomain redirects to a url with a specified url and/or protocol (ssl)
		sets FINALURL
		*/
		function resolveUrl(url)
		{
			url = prepareUrl(url);
		
			cfhttp(method="HEAD", charset="utf-8", url=url, redirect="false", result="result")
			{
				cfhttpparam(name="q", type="formfield", value="cfml");
			}
			if(FindOneOf(result.Statuscode, "200", 0) == 1)
			{
				FINALURL = url;
			}
			else if(FindOneOf(result.Statuscode, "301", 0) == 1 || FindOneOf(result.Statuscode, "302", 0) == 1)
			{
				resolveUrl(result.Responseheader.Location);
				//WriteOutput("Redirected ");
			}
			else
			{
				FINALURL = "INVALID";
				//WriteOutput("Resolved");
			}
		}
		
		//adds the protocol (http) if not present
		function prepareURL(url)
		{
			if (FindOneOf("http://", url, 0) == 0 && FindOneOf("https://", url, 0) == 0)
			{
				return "http://" & url;
			}
			else
			{
				return url;
			}
		}	
		
		//uses cfhttp to get the title from the fileContent property
		function getTitle(url)
		{
			if (url != "INVALID")
			{
				cfhttp(method="GET", charset="utf-8", url=url, result="result")
				{
					cfhttpparam(name="q", type="formfield", value="cfml");
				}
				//WriteDUMP(result);
				return sanatizeString(ReReplace(result.fileContent, ".*<title>([^<>]*)</title>.*", "\1"));
			}
			else
			{
				return "NO TITLE";
			}
		}
		
		//uses cfhttp to get the domain from the fileContent property
		function getDomain(url)
		{
			cfhttp(method="HEAD", charset="utf-8", url=url, result="result")
				{
					cfhttpparam(name="q", type="formfield", value="cfml");
				}
			
			domain = ReReplace(result.Header, ".*; domain=([^<>]*);.*", "\1");
			if (Mid(domain, 1, 1) == ".")
			{
				l = Len(domain);
				domain = Mid(domain, 2, l - 1);
			}				
		}
		
		//Generate thumbnails from each page of a PDF generated with CFDOCUMENT
		function getThumbnail(FILENAME)
		{
			thumbnailsDirectory = FILEPATH & "#FILENAME#_thumbs";
			//WriteOutput(thumbnailsDirectory);
			//WriteOutput(URLTITLE);
			pdfService = new pdf();
			pdfService.setSource(FILEPATH & FILENAME);
			//pdfInfo to iterate through them and create thumbnails
			PDFInfo = pdfService.getPdfInfo(name="pdfinfo");
			pageCount = PDFInfo.TotalPages;
			
			/*Generate a thumbnail, scale sets size of the thumnbail in comparison to the original
			thumbnails are named FILENAME + "_page_" + pageNumber */
			pdfService.thumbnail(destination=thumbnailsDirectory, scale=60, overwrite=true);
			for(i=1;i lte pageCount;i++)
			{
				WriteOutput("<span class='thumb'><a href='./#SUBDIR#/#FILENAME#_thumbs/#URLTITLE#_page_#i#.jpg' target='_blank'>Page #i#<br/><img src='./#SUBDIR#/#FILENAME#_thumbs/#URLTITLE#_page_#i#.jpg'></a></span>");
			}
		}
		
		//sanitzes string
		//TODO: make this more robust
		function sanatizeString(dirtyString)
		{
			return Replace(Replace(Replace(Replace(Replace(Replace(Replace(dirtyString, ":", ""), "/", ""), "\", ""), "?", ""), "!", ""), ";", ""), "'", "");
		}
		
		//remove working folder/files
		public function cleanUp()
		{			
			if (DirectoryExists(FILEPATH & PDFFILE & "_thumbs"))
			{
				DirectoryDelete(FILEPATH & PDFFILE & "_thumbs", true);
			}
			if (FileExists(FILEPATH & PDFFILE))
			{
				FileDelete(FILEPATH & PDFFILE);
			}
			if (DirectoryExists(FILEPATH))
			{
				DirectoryDelete(FILEPATH, true);
			}
		}
		
	</cfscript>
</head>
<body>
	<div class="form">
		<h1>Web Page to PDF to Thumbnails</h1>
		<h3>Plug in your favorite website and watch me cut it into little peices.</h3>

		<cfform action="WebPageToPDF.cfm" method="post" preservedata="true" >
			URL: <cfinput type="text" id="tbURL" name="tbURL">
			<input type="submit" value="Get Thumbs" name="btnGetThumbs">
			<input type="submit" value="Clean Up" name="btnCleanUp">
		</cfform>
	
		<cfif IsDefined("FORM.btnGetThumbs")>
			<cfif FORM.tbURL is not "">
				<cfset FINALURL = FORM.tbURL>
				 <cftry>
					<cfset prepForPDF(FINALURL)>
					<cfoutput><h4>#FINALURL# : #URLTITLE#</h4></cfoutput>
					<!--<cfoutput><h4>#getDomain(FINALURL)#</h4></cfoutput>-->
					<cfif FINALURL neq "INVALID">
						<cfdocument format="PDF" src="#FINALURL#" FILENAME="#FILEPATH##PDFFILE#" overwrite="yes"></cfdocument>
						<cfoutput>
							<div class='thumbsContainer'>
								#getThumbnail(PDFFILE)#
							</div>
						</cfoutput>						
					<cfelse>
						<cfthrow message="Invalid URL">
					</cfif>
					
					<cfcatch>
						<div class="errorMessage">
							<b>Error Message:</b><cfoutput> #cfcatch.message#</cfoutput><br/>
							<cfif cfcatch.detail neq "">
								<b>Error Detail:</b><cfoutput> #cfcatch.detail#</cfoutput>
							</cfif>
						</div>
					</cfcatch>
				</cftry>
			</cfif>
		</cfif>
		<cfif IsDefined("FORM.btnCleanUp")>
			<cfset cleanUp()>
		</cfif>
	
	</div>
</body>
</html>
