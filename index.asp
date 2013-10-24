<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<meta http-equiv="expires" content="-1"/>
	<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
	<meta name="copyright" content="2013, Web Solutions"/>
	<meta http-equiv="X-UA-Compatible" content="IE=edge" >
	<title>Retroactive References 2</title>
	<link rel="stylesheet" href="css/bootstrap.min.css" />
	<style type="text/css">
		body
		{
			padding: 10px;
		}
		#selected-structural-element, #to-be-referenced-element
		{
			padding-left: 25px;
		}
	</style>
	<script type="text/javascript" src="js/jquery-1.8.3.min.js"></script>
	<script type="text/javascript" src="js/bootstrap.min.js"></script>
	<script type="text/javascript" src="rqlconnector/Rqlconnector.js"></script>
	<script type='text/javascript'>
		var LoginGuid = '<%= session("loginguid") %>';
		var SessionKey = '<%= session("sessionkey") %>';
		var RqlConnectorObj = new RqlConnector(LoginGuid, SessionKey);
		var ClipboardItemGuid;
		var ClipboardItemType;
		var ContentClassGuid;
		var ContentClassElementGuid = '<%= session("treeguid") %>';
		var LinkName;
		var GlobalThreadIdCounter = 0;
	
		$(document).ready(function() {
			$('#reference-option-dialog').modal('show');
			
			$('#referencebutton').hide();
			
			LoadSelectedItem(ContentClassElementGuid);
			LoadTargetedItem();
		});
		
		function LoadSelectedItem(StructureElementGuid)
		{
			var ThreadId = getThread('status');
			displayToThread(ThreadId, 'warning', 'Loading selected element.');
		
			var strRQLXML = '<PROJECT><TEMPLATE><ELEMENT action="load" guid="' + StructureElementGuid + '"/></TEMPLATE></PROJECT>';
			RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
				ContentClassGuid = $(retXML).find('ELEMENT').attr('templateguid'); 
				LoadContentClass(ContentClassGuid);
			
				var StructureElementName = $(retXML).find('ELEMENT').attr('eltname');
				var StructureElementType = $(retXML).find('ELEMENT').attr('elttype');
				var IsDynamicStructureElement = $(retXML).find('ELEMENT').attr('eltisdynamic');
				
				$('#selected-structural-element').append(StructureElementName);
				$('#selected-structural-element img').attr('src', '/cms/icons/TreeType' + StructureElementType +'.gif');
				LinkName = StructureElementName;
				
				if(IsDynamicStructureElement == '1')
				{
					displayToThread(ThreadId, 'error', 'ERROR:  The current selected element is a dynamic link.  This plugin will not work with dynamic links.', true);
				}else{
					displayToThread(ThreadId, 'ok', 'Selected element loaded.', true, true);
					enableUI();
				}
			});
		}
		
		function LoadContentClass(ContentClassGuid)
		{
			var ThreadId = getThread('status');
			displayToThread(ThreadId, 'warning', 'Loading selected content class.');
			
			var strRQLXML = '<PROJECT><TEMPLATE action="load" guid="' + ContentClassGuid + '"/></PROJECT>';
			RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
				var ContentClassName = $(retXML).find('TEMPLATE').attr('name');
				$('#content-class-name').append(ContentClassName);
				
				displayToThread(ThreadId, 'ok', 'Selected content class loaded.', true, true);
				enableUI();
			});
		}
		
		function LoadTargetedItem()
		{
			var ThreadId = getThread('status');
			displayToThread(ThreadId, 'warning', 'Loading item to be referenced.');

			var objClipBoard = top.opener.parent.frames.ioClipboard.document;
			objClipBoard = $(objClipBoard).find('#ClipboardData');
		
			// check clipboard
			if ($(objClipBoard).find('input:checked').length == 0)
			{
				displayToThread(ThreadId, 'error', 'No items selected in clipboard.', true, false);
				return;
			}
			else if ($(objClipBoard).find('input:checked').length > 1)
			{
				displayToThread(ThreadId, 'error', 'Too many items selected in clipboard.', true, false);
				return;
			}
			
			// get select clipboard item guid and type
			ClipboardItemGuid = $(objClipBoard).find('input:checked:first').parent().parent().attr('id');
			ClipboardItemType = $(objClipBoard).find('input:checked:first').parent().parent().attr('elttype');
			
			// check clipboard item type
			if((ClipboardItemType != 'link') && (ClipboardItemType != 'page'))
			{
				displayToThread(ThreadId, 'error', 'Selected clipboard item is not a link or page.  Cannot create references.', true, false);
				return;
			}

			// load to be referenced item information
			if(ClipboardItemType == 'link')
			{
				var strRQLXML = '<LINK action="load" guid="' + ClipboardItemGuid + '" />';
				RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
					var ToBeReferencedLinkName = $(retXML).find('LINK').attr('value');
					if(ToBeReferencedLinkName == null)
					{
						ToBeReferencedLinkName = $(retXML).find('LINK').attr('eltname');
					}
					var ToBeReferencedLinkType = $(retXML).find('LINK').attr('elttype');
					var ToBeReferencedLinkParentPage = $(retXML).find('LINK').attr('pageguid');

					strRQLXML = '<PAGE action="load" guid="' + ToBeReferencedLinkParentPage + '" />';
					RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
						var ToBeReferencedLinkParentPageHeadline = $(retXML).find('PAGE').attr('headline');

						$('#to-be-referenced-element-parent-page').append('<img src="/cms/icons/Page.gif" />');
						$('#to-be-referenced-element-parent-page').append(ToBeReferencedLinkParentPageHeadline);
						$('#to-be-referenced-element').append('<img src="/cms/icons/TreeType' + ToBeReferencedLinkType +'.gif" />');
						$('#to-be-referenced-element').append(ToBeReferencedLinkName);						
						
						displayToThread(ThreadId, 'ok', 'Item to be referenced loaded.', true, true);
						enableUI();
					});
				});
			}
			else if(ClipboardItemType == 'page')
			{
				var strRQLXML = '<PAGE action="load" guid="' + ClipboardItemGuid + '" />';
				RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
					var ToBeReferencedPageHeadline = $(retXML).find('PAGE').attr('headline');
					$('#targeteditem').append('<div class="contentclass">&nbsp;</div>');
					$('#targeteditem').append('<div class="structuralelement"><img src="/cms/icons/Page.gif" >&nbsp;' + ToBeReferencedPageHeadline + '</div>');
					
					$('#to-be-referenced-element').append('<img src="/cms/icons/Page.gif" />');
					$('#to-be-referenced-element').append(ToBeReferencedPageHeadline);
					
					displayToThread(ThreadId, 'ok', 'Item to be referenced loaded.', true, true);
					enableUI();
				}, 'xml');
			}
		}

		function referenceAll()
		{
			// disable UI
			$('#reference-option-dialog').modal('hide');

			// prereference element in template
			if($('#prereferenceintemplate').is(':checked'))
			{
				prereferenceInTemplate(ContentClassElementGuid, ClipboardItemType, ClipboardItemGuid);
			}
			
			var ThreadId = getThread('status');
			displayToThread(ThreadId, 'warning', 'Listing all page instances of current content class.');

			// get a list of all pages instances
			var strRQLXML = '<PAGE action="xsearch" pagesize="-1" maxhits="-1"><SEARCHITEMS><SEARCHITEM key="contentclassguid" value="' + ContentClassGuid + '" operator="eq"></SEARCHITEM></SEARCHITEMS></PAGE>';
			RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
				var PageArray0 = new Array();
				var PageArray1 = new Array();
				var PageArray2 = new Array();
				var PageArray3 = new Array();
			
				$(retXML).find('PAGE').each( function(index) {
					var PageObj = new Object();
					PageObj.guid = $(this).attr('guid');
					PageObj.name = $(this).attr('headline');
					
					switch(index % 4)
					{
						case 0:
							PageArray0.push(PageObj);
							break;
						case 1:
							PageArray1.push(PageObj);
							break;
						case 2:
							PageArray2.push(PageObj);
							break;
						case 3:
							PageArray3.push(PageObj);
							break;
						default:
							PageArray0.push(PageObj);
					}
				});
				
				displayToThread(ThreadId, 'ok', 'Listing completed', true, true);

				var ThreadId1 = getThread('processing');
				var ThreadId2 = getThread('processing');
				var ThreadId3 = getThread('processing');
				var ThreadId4 = getThread('processing');

				referencePerPage(PageArray0, ClipboardItemType, ClipboardItemGuid, ThreadId1);
				referencePerPage(PageArray1, ClipboardItemType, ClipboardItemGuid, ThreadId2);
				referencePerPage(PageArray2, ClipboardItemType, ClipboardItemGuid, ThreadId3);
				referencePerPage(PageArray3, ClipboardItemType, ClipboardItemGuid, ThreadId4);
			});
		}
		
		function prereferenceInTemplate(TemplateElementGuid, ToBeReferencedItemType, ToBeReferencedItemGuid)
		{
			var ThreadId = getThread('processing');
			displayToThread(ThreadId, 'warning', 'Preassigning reference to template element');
		
			// delete prereferenced link first
			var strRQLXML = '<TEMPLATE><ELEMENT action="load" guid="' + TemplateElementGuid + '"/></TEMPLATE>';
			RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
				strRQLXML = '';
				var existingPrereferencedItemGuid = $(retXML).find('ELEMENT').attr('eltrefelementguid');
				if(existingPrereferencedItemGuid != null)
				{
					strRQLXML = '<TEMPLATE><ELEMENT action="unlink" guid="' + TemplateElementGuid + '"><ELEMENT guid="' + existingPrereferencedItemGuid + '"/></ELEMENT></TEMPLATE>';
				}
				
				RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
					if(ToBeReferencedItemType == 'link')
					{
						strRQLXML = '<CLIPBOARD action="ReferenceToLink" guid="' + TemplateElementGuid + '" type="project.4145"><ENTRY guid="' + ToBeReferencedItemGuid + '" type="link" /></CLIPBOARD>';
					}
					else if(ToBeReferencedItemType == 'page')
					{
						strRQLXML = '<CLIPBOARD action="ReferenceToPage" guid="' + TemplateElementGuid + '" type="project.4145"><ENTRY guid="' + ToBeReferencedItemGuid + '" type="page" /></CLIPBOARD>';
					}
					
					RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
						displayToThread(ThreadId, 'ok', 'Template element preassigned', true);
						killThread(ThreadId);
						enabledCompletionUI();
					});
				});
			});
		}
		
		function referencePerPage(PageArray, ToBeReferencedItemType, ToBeReferencedItemGuid, ThreadId)
		{
			var PageObj = PageArray.shift();
			if(PageObj != null)
			{
				var ToBeProcessItemGuid = PageObj.guid;
				var ToBeProcessItemHeadline = PageObj.name;
				
				displayToThread(ThreadId, 'warning', '(' + PageArray.length + ') items remaining.  Processing: ' + ToBeProcessItemHeadline, true);

				// get element guid from current page instance by linkname
				var strRQLXML = '<PAGE guid="' + ToBeProcessItemGuid + '" ><LINKS action="load"/></PAGE>';

				RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
					ToBeProcessItemGuid = $(retXML).find('LINK[eltname=\'' + LinkName + '\']').attr('guid');

					if(ToBeReferencedItemType == 'link')
					{
						strRQLXML = '<CLIPBOARD action="ReferenceToLink" guid="' + ToBeProcessItemGuid + '" type="link"><ENTRY guid="' + ToBeReferencedItemGuid + '" type="link" /></CLIPBOARD>';
					}
					else if(ToBeReferencedItemType == 'page')
					{
						strRQLXML = '<CLIPBOARD action="ReferenceToPage" guid="' + ToBeProcessItemGuid + '" type="link"><ENTRY guid="' + ToBeReferencedItemGuid + '" type="page" /></CLIPBOARD>';
					}
					
					RqlConnectorObj.SendRql(strRQLXML, false, function(retXML){
						referencePerPage(PageArray, ToBeReferencedItemType, ToBeReferencedItemGuid, ThreadId);
					});
				});
			}
			else
			{
				displayToThread(ThreadId, 'ok', 'Processing completed.', true);
				killThread(ThreadId);
				enabledCompletionUI();
			}
		}
		
		function getThread(threadArea)
		{
			var ThreadId = 't' + GlobalThreadIdCounter;
			GlobalThreadIdCounter++;
			var ThreadClone = $('#thread-temnplate>div').clone();
			$(ThreadClone).attr('id', ThreadId);
			$('#' + threadArea).append(ThreadClone);
			$(ThreadClone).show();
			return ThreadId;
		}
		
		function displayToThread(threadId, status, text, overwrite, bkillThread)
		{
			var threadDom = $('#' + threadId);
			switch(status){
				case 'ok':
					$(threadDom).toggleClass('alert-success', true);
					$(threadDom).toggleClass('alert-error', false);
					break
				case 'warning':
					$(threadDom).toggleClass('alert-success', false);
					$(threadDom).toggleClass('alert-error', false);
					break
				case 'error':
					$(threadDom).toggleClass('alert-success', false);
					$(threadDom).toggleClass('alert-error', true);
					break
			}
			
			if(overwrite)
			{
				$(threadDom).empty();
			}
				
			$(threadDom).append('<div>' + text + '</div>');
			
			if(bkillThread)
			{
				killThread(threadId);
			}
		}
		
		function killThread(threadId)
		{
			var threadDom = $('#' + threadId);
			$(threadDom).remove();
		}
		
		function getRunningThreadCount(threadArea)
		{
			return $('#' + threadArea + ' .thread').length;
		}
		
		function enableUI()
		{
			if(getRunningThreadCount('status') == 0)
			{
				$('#referencebutton').show();
			}
			else
			{
				$('#referencebutton').hide();
			}
		}
		
		function enabledCompletionUI()
		{
			if(getRunningThreadCount('processing') == 0)
			{
				var ThreadId = getThread('processing');
				displayToThread(ThreadId, 'ok', 'All processing completed.');
			}
		}
	</script>
</head>
<body>
	<div id="reference-option-dialog" class="modal hide fade" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
		<div class="modal-header">
			<h3>Reference Item In Clipboard For All Page Instances</h3>
		</div>
		<div class="modal-body">
			<table class="table table-condensed">
				<tr>
					<th>Selected Item</th>
					<th>Item to be Referenced</th>
				</tr>
				<tr>
					<td id="content-class-name"><img src="/cms/icons/template.gif" /></td>
					<td id="to-be-referenced-element-parent-page"></td>
				</tr>
				<tr class="success">
					<td id="selected-structural-element"><img src="" /></td>
					<td id="to-be-referenced-element"></td>
				</tr>
			</table>
			<label for="prereferenceintemplate"><input type="checkbox" id="prereferenceintemplate" checked="checked" /> Preassign reference in template (apply to all future pages)</label>
			<br />
			<div class="alert">
				<strong>Warning: </strong>
				This action will be applied to the selected link element in all page instances of this Content Class. Any existing references and connected pages will be replaced.
			</div>
			<div id="status"></div>
		</div>
		<div class="modal-footer">
			<a href="#" class="btn btn-success" id="referencebutton" onclick="referenceAll();">Reference</a>
		</div>
	</div>
	<div id="processing">
	</div>
	<div id="thread-temnplate" style="display: none;">
		<div class="thread alert"></div>
	</div>
</body>
</html>