function RetroactiveReferences(RqlConnectorObj, ContentClassElementGuid, ContentClassElementTreeType, ThreadCount) {
	this.RqlConnectorObj = RqlConnectorObj;
	this.ThreadCount = ThreadCount;
	
	this.TemplateOptionDialog = '#reference-option-dialog';
	this.TemplateSource = '#template-source';
	this.TemplateSourceError = '#template-source-error';
	this.TemplateTarget = '#template-target';
	this.TemplateTargetError = '#template-target-error';
	this.TemplatePrereferenceInTemplate = '#template-pre-reference-in-template';
	this.TemplateStatus = '#template-status';

	this.TemplateTypeMismatch = '#template-type-mismatch';
	this.TemplateProcessingStatus = '#template-processing-status';
	this.TemplateProcessingStatusClear = '#template-processing-status-clear';
	
	this.Init(ContentClassElementGuid, ContentClassElementTreeType);
}

RetroactiveReferences.prototype.Init = function(ContentClassElementGuid, ContentClassElementTreeType) {
	var ThisClass = this;
	
	$(this.TemplateOptionDialog).modal('show');
	
	this.DrawPrereferenceInTemplate(ContentClassElementGuid);
	this.DrawSelectedTreeElement(ContentClassElementGuid, ContentClassElementTreeType);
	this.DrawSelectedClipboardElement();
	
	$('body').on('click', '#reference-button', function(){
		var ElementDataContainer = '.element';
		var SourceDataContainer = $(ThisClass.TemplateSource).attr('data-container');
		var TargetDataContainer = $(ThisClass.TemplateTarget).attr('data-container');
		
		var ContentClassGuid = $(SourceDataContainer).find(ElementDataContainer).attr('data-content-class-guid');

		var SourceGuid = $(SourceDataContainer).find(ElementDataContainer).attr('data-guid');
		var SourceType = $(SourceDataContainer).find(ElementDataContainer).attr('data-type');
		var SourceName = $(SourceDataContainer).find(ElementDataContainer).attr('data-name');
		var SourceTreeType = $(SourceDataContainer).find(ElementDataContainer).attr('data-tree-type');
		
		var TargetGuid = $(TargetDataContainer).find(ElementDataContainer).attr('data-guid');
		var TargetType = $(TargetDataContainer).find(ElementDataContainer).attr('data-type');
		var TargetTreeType = $(TargetDataContainer).find(ElementDataContainer).attr('data-tree-type');
		
		var IsReferenceable = ThisClass.IsReferenceable(SourceGuid, SourceType, TargetGuid, TargetType);
		
		if(!IsReferenceable){
			ThisClass.UpdateArea(ThisClass.TemplateTypeMismatch);

			return;
		}
		
		ThisClass.StartReference(ContentClassGuid, SourceGuid, SourceName, SourceTreeType, TargetGuid, TargetTreeType);
	});
}

RetroactiveReferences.prototype.DrawPrereferenceInTemplate = function(ContentClassElementGuid) {
	var ThisClass = this;
	var RqlXml = '<PROJECT><TEMPLATE><ELEMENT action="load" guid="' + ContentClassElementGuid + '"/></TEMPLATE></PROJECT>';
	
	this.RqlConnectorObj.SendRql(RqlXml, false, function(Data){
		var ContentClassGuid = $(Data).find('ELEMENT').attr('templateguid'); 

		var ElementObj = {
			guid: ContentClassGuid
		};
		
		ThisClass.UpdateArea(ThisClass.TemplatePrereferenceInTemplate, undefined, ElementObj);
	});
}

RetroactiveReferences.prototype.DrawSelectedTreeElement = function(ContentClassElementGuid, ContentClassElementTreeType) {
	var ThisClass = this;
	var RqlXml = '<PROJECT><TEMPLATE><ELEMENT action="load" guid="' + ContentClassElementGuid + '"/></TEMPLATE></PROJECT>';
	
	this.RqlConnectorObj.SendRql(RqlXml, false, function(Data){
		var ElementObj = {};
		
		var ContentClassGuid = $(Data).find('ELEMENT').attr('templateguid');
	
		var IsDynamicElement = $(Data).find('ELEMENT').attr('eltisdynamic');
		
		if(IsDynamicElement == '1'){
			ElementObj.name = 'Dynamic element cannot be used';
			
		} else {
			var ElementName = $(Data).find('ELEMENT').attr('eltname');
			var ElementType = $(Data).find('ELEMENT').attr('elttype');
			var ElementIcon = ThisClass.GetIconUrl(ElementType);
		
			ElementObj.guid = ContentClassElementGuid;
			ElementObj.name = ElementName;
			ElementObj.type = ElementType;
			ElementObj.treetype = ContentClassElementTreeType;
			ElementObj.icon = ElementIcon;
			ElementObj.contentclassguid = ContentClassGuid;
			
			ThisClass.UpdateArea(ThisClass.TemplateSource, undefined, ElementObj);
		}
	});
}

RetroactiveReferences.prototype.DrawSelectedClipboardElement = function() {
	var ThisClass = this;
	var ElementObj = {};
	
	var ClipBoardObj = top.opener.parent.frames.ioClipboard.document;
	ClipBoardObj = $(ClipBoardObj).find('[name=ioClipboardForm]');

	var SelectedItem = ClipBoardObj.find('input:checked');
	
	if(SelectedItem.length != 1){
		ElementObj.name = 'Please select one item in clipboard.';
		ThisClass.UpdateArea(ThisClass.TemplateTargetError, undefined, ElementObj);

		return;
	}
	
	SelectedItem = SelectedItem.closest('[elttype],[data-elttype]');
	
	var Type = SelectedItem.attr('elttype');
	if(!Type){
		Type = SelectedItem.attr('data-elttype');
	}
	
	var Guid = SelectedItem.attr('id');

	if(!Guid){
		Guid = SelectedItem.attr('data-guid');
	}
	
	var Icon = SelectedItem.find('.clipboardImg').attr('src');

	if(!Icon){
		Icon = SelectedItem.find('img:last').attr('src');
	}
	
	var Name = SelectedItem.find('.clipboardItemLabel').text();
	if(!Name){
		Name = SelectedItem.text();
	}
	
	Name = $.trim(Name);
	
	ElementObj.guid = Guid;
	ElementObj.name = Name;
	ElementObj.icon = Icon;
	ElementObj.treetype = Type;
	
	var RqlXml;
	
	switch(Type) {
		case 'link':
			RqlXml = '<LINK action="load" guid="' + Guid + '" />';
			ThisClass.RqlConnectorObj.SendRql(RqlXml, false, function(data){
				Type = $(data).find('LINK').attr('elttype');
				
				Name = $(data).find('LINK').attr('value');
				if(!Name){
					Name = $(data).find('LINK').attr('eltname');
				}
				
				ElementObj.name = Name;
				ElementObj.type = Type;
				ElementObj.icon = ThisClass.GetIconUrl(Type);
				
				ThisClass.UpdateArea(ThisClass.TemplateTarget, undefined, ElementObj);
			});
			break;
		case 'page':
			RqlXml = '<PAGE action="load" guid="' + Guid + '" />';
			ThisClass.RqlConnectorObj.SendRql(RqlXml, false, function(data){
			
				Type = '0';
				
				ElementObj.icon = ThisClass.GetIconUrl(Type);
				ElementObj.type = Type;
				
				ThisClass.UpdateArea(ThisClass.TemplateTarget, undefined, ElementObj);
			});
			break;
		case 'element':
			RqlXml = '<ELT action="load" guid="' + Guid + '"/>';
			ThisClass.RqlConnectorObj.SendRql(RqlXml, false, function(data){		
				Type = $(data).find('ELT').attr('elttype');
				Name = $(data).find('ELT').attr('eltname');

				ElementObj.name = Name;
				ElementObj.type = Type;
				ElementObj.icon = ThisClass.GetIconUrl(Type);

				ThisClass.UpdateArea(ThisClass.TemplateTarget, undefined, ElementObj);
			});
			break;
		default:
			ThisClass.UpdateArea(ThisClass.TemplateTargetError, undefined, ElementObj);
	}
}

RetroactiveReferences.prototype.GetIconUrl = function(Type) {
	var IconUrl;
	
	switch(Type)
	{
		case '0':
			IconUrl = '/cms/icons/Page.gif';
			break;
		case '1':
			IconUrl = '/cms/icons/TreeType4156.gif';
			// Standard Field - Text
			break;
		case '5':
			IconUrl = '/cms/icons/TreeType4156.gif';
			// Standard Field - Date
			break;
		case '39':
			IconUrl = '/cms/icons/TreeType4156.gif>';
			// Standard Field - Time
			break;
		case '48':
			IconUrl = '/cms/icons/TreeType4156.gif';
			// Standard Field - Numeric
			break;
		case '999':
			IconUrl = '/cms/icons/TreeType4156.gif';
			// Standard Field - User defined
			break;
		case '50':
			IconUrl = '/cms/icons/TreeType4156.gif';
			// Standard Field - e-mail
			break;
		case '51':
			IconUrl = '/cms/icons/TreeType4156.gif';
			// Standard Field - URL
			break;
		case '31':
			IconUrl = '/cms/icons/TreeType4157.gif';
			// Text ASCI
			break;
		case '32':
			IconUrl = '/cms/icons/TreeType4157.gif';
			// Text HTML
			break;
		case '26':
			IconUrl = '/cms/icons/TreeType26.gif';
			// Anchor as text 	
			break;
		case '27':
			IconUrl = '/cms/icons/TreeType27.gif';
			// Anchor as image  	
			break;
		case '2627':
			IconUrl = '/cms/icons/TreeType2627.gif';
			// Anchor, not yet defined as text or image 	  	
			break;
		case '15':
			IconUrl = '/cms/icons/TreeType15.gif';
			// Area 	  	
			break;
		case '23':
			IconUrl = '/cms/icons/TreeType23.gif';
			// Browse
			break;
		case '28':
			IconUrl = '/cms/icons/TreeType28.gif';
			// Container
			break;
		case '3':
			IconUrl = '/cms/icons/TreeType3.gif';
			// Frame
			break; 	
		case '13':
			IconUrl = '/cms/icons/TreeType13.gif';
			// List
			break; 	
		case '99':
			IconUrl = '/cms/icons/TreeType99.gif';
			// Site map 
			break; 
		case '24':
			IconUrl = '/cms/icons/TreeType24.gif';
			// Hit list  
			break; 
		case '2':
			IconUrl = '/cms/icons/TreeType2.gif';
			// Image  
			break; 
		case '38':
			IconUrl = '/cms/icons/TreeType38.gif';
			// Image  
			break; 
		default:
			IconUrl = '/cms/icons/Page.gif';
			break;
	}
	
	return IconUrl;
}

RetroactiveReferences.prototype.IsReferenceable = function(SourceGuid, SourceType, TargetGuid, TargetType) {
	var IsReferenceable = false;
	
	// Anchor as text, Anchor as image, Container, List
	var ReferenceableLinkSourceTypes = ['26', '27', '28', '13'];
	
	// Anchor as text, Anchor as image, Container, List, Page
	var ReferenceableLinkTargetTypes = ['26', '27', '28', '13', '0'];
	
	// Standard Field - Text, Standard Field - Date, Standard Field - Time, Standard Field - Numeric, Standard Field - User defined, Standard Field - e-mail, Standard Field - URL, Image, Media
	var ReferenceableElementSourceTypes = ['1', '5', '39', '48', '999', '50', '51', '2', '38'];
	
	// Standard Field - Text, Standard Field - Date, Standard Field - Time, Standard Field - Numeric, Standard Field - User defined, Standard Field - e-mail, Standard Field - URL, Image, Media
	var ReferenceableElementTargetTypes = ['1', '5', '39', '48', '999', '50', '51', '2', '38'];
	
	if($.inArray(SourceType, ReferenceableLinkSourceTypes) > -1){
		// link
		if($.inArray(TargetType, ReferenceableLinkTargetTypes) > -1){
			IsReferenceable = true;
		}
	} else if($.inArray(SourceType, ReferenceableElementSourceTypes) > -1){
		// element
		if($.inArray(TargetType, ReferenceableElementTargetTypes) > -1){
			IsReferenceable = true;
		}
	}
	
	return IsReferenceable;
}

RetroactiveReferences.prototype.StartReference = function(ContentClassGuid, SourceGuid, SourceName, SourceTreeType, TargetGuid, TargetTreeType) {
	$(this.TemplateOptionDialog).modal('hide');

	if(this.IsPrereferenceInTemplate()){
		this.PrereferenceInTemplate(SourceGuid, SourceTreeType, TargetGuid, TargetTreeType);
	}
	
	this.ReferenceAll(ContentClassGuid, SourceName, TargetGuid, TargetTreeType)
}


RetroactiveReferences.prototype.IsPrereferenceInTemplate = function() {
	var IsPrereferenceInTemplate = false;
	var PrereferenceInTemplateContainer = $(this.TemplatePrereferenceInTemplate).attr('data-container');
	
	if($(PrereferenceInTemplateContainer).find('input:checked').length > 0){
		IsPrereferenceInTemplate = true;
	}
	
	return IsPrereferenceInTemplate;
}

RetroactiveReferences.prototype.PrereferenceInTemplate = function(SourceGuid, SourceTreeType, TargetGuid, TargetTreeType) {
	var ThisClass = this;

	var ElementObj = {
		'name': 'content class element',
		'guid': SourceGuid
	};
	ThisClass.UpdateArea(ThisClass.TemplateProcessingStatus, undefined, ElementObj);

	// delete prereferenced link first
	var RqlXml = '<TEMPLATE><ELEMENT action="load" guid="' + SourceGuid + '"/></TEMPLATE>';
	this.RqlConnectorObj.SendRql(RqlXml, false, function(data){
		RqlXml = '';
		var ExistingPrereferencedGuid = $(data).find('ELEMENT').attr('eltrefelementguid');
		if(ExistingPrereferencedGuid)
		{
			RqlXml = '<TEMPLATE><ELEMENT action="unlink" guid="' + SourceGuid + '"><ELEMENT guid="' + ExistingPrereferencedGuid + '"/></ELEMENT></TEMPLATE>';
		}
		
		ThisClass.RqlConnectorObj.SendRql(RqlXml, false, function(data){
			switch(TargetTreeType) {
				case 'link':
					RqlXml = '<CLIPBOARD action="ReferenceToLink" guid="' + SourceGuid + '" type="' + SourceTreeType + '"><ENTRY guid="' + TargetGuid + '" type="link" /></CLIPBOARD>';
					break;
				case 'page':
					RqlXml = '<CLIPBOARD action="ReferenceToPage" guid="' + SourceGuid + '" type="' + SourceTreeType + '"><ENTRY guid="' + TargetGuid + '" type="page" /></CLIPBOARD>';
					break;
				case 'element':
					RqlXml = '<CLIPBOARD action="ReferenceToElement" guid="' + SourceGuid + '" type="' + SourceTreeType + '"><ENTRY guid="' + TargetGuid + '" type="element"/></CLIPBOARD>';
					break;
			}
			
			ThisClass.RqlConnectorObj.SendRql(RqlXml, false, function(data){
				// prereferenced

				ThisClass.UpdateArea(ThisClass.TemplateProcessingStatusClear, ' .' + ElementObj.guid);
			});
		});
	});
}

RetroactiveReferences.prototype.GetAllPageInstancesArray = function(ContentClassGuid, CallbackFunc) {
	var ThisClass = this;

	var RqlXml = '<PAGE action="xsearch" pagesize="-1" maxhits="-1"><SEARCHITEMS><SEARCHITEM key="contentclassguid" value="' + ContentClassGuid + '" operator="eq"></SEARCHITEM></SEARCHITEMS></PAGE>';
	this.RqlConnectorObj.SendRql(RqlXml, false, function(data){
		var PageInstancesArray = [];

		$(data).find('PAGE').each( function(index) {
			var PageObj = {guid: $(this).attr('guid'), name: $(this).attr('headline')};
			PageInstancesArray.push(PageObj);
		});

		CallbackFunc(PageInstancesArray);
	});
}

RetroactiveReferences.prototype.ReferenceAll = function(ContentClassGuid, SourceName, TargetGuid, TargetTreeType) {
	var ThisClass = this;

	this.GetAllPageInstancesArray(ContentClassGuid, function(PageInstancesArray){
		ThisClass.ReferenceAllPages(PageInstancesArray, SourceName, TargetGuid, TargetTreeType);
	});
}

RetroactiveReferences.prototype.ReferenceAllPages = function(PageInstancesArray, SourceName, TargetGuid, TargetTreeType) {
	var ThisClass =  this;
	var PageObj = PageInstancesArray.shift();
	
	if(PageObj){
		PageObj.remaining = PageInstancesArray.length;
		
		this.ReferencePage(PageObj, SourceName, TargetGuid, TargetTreeType, function(){
			ThisClass.ReferenceAllPages(PageInstancesArray, SourceName, TargetGuid, TargetTreeType);
		});
	} else {
		// done
	}
}

RetroactiveReferences.prototype.ReferencePage = function(PageObj, SourceName, TargetGuid, TargetTreeType, CallbackFunc) {
	var ThisClass = this;

	if(PageObj)
	{
		ThisClass.UpdateArea(ThisClass.TemplateProcessingStatus, undefined, PageObj);
		
		var RqlXml = '<PAGE guid="' + PageObj.guid + '"><LINKS action="load"/><ELEMENTS action="load"/></PAGE>';

		ThisClass.RqlConnectorObj.SendRql(RqlXml, false, function(data){
			var SourceGuid = $(data).find('[eltname="' + SourceName + '"]').attr('guid');
			switch(TargetTreeType) {
				case 'link':
					RqlXml = '<CLIPBOARD action="ReferenceToLink" guid="' + SourceGuid + '" type="link"><ENTRY guid="' + TargetGuid + '" type="link" /></CLIPBOARD>';
					break;
				case 'page':
					RqlXml = '<CLIPBOARD action="ReferenceToPage" guid="' + SourceGuid + '" type="link"><ENTRY guid="' + TargetGuid + '" type="page" /></CLIPBOARD>';
					break;
				case 'element':
					RqlXml = '<CLIPBOARD action="ReferenceToElement" guid="' + SourceGuid + '" type="element"><ENTRY guid="' + TargetGuid + '" type="element"/></CLIPBOARD>';
					break;
			}
			
			ThisClass.RqlConnectorObj.SendRql(RqlXml, false, function(data){
				ThisClass.UpdateArea(ThisClass.TemplateProcessingStatusClear, ' .' + PageObj.guid);
				
				if(CallbackFunc){
					CallbackFunc();
				}
			});
		});
	}
}

RetroactiveReferences.prototype.UpdateArea = function(TemplateId, AdditionalContainerData, Data){
	var ContainerId = $(TemplateId).attr('data-container');
	if(AdditionalContainerData){
		ContainerId += AdditionalContainerData;
	}
	var TemplateAction = $(TemplateId).attr('data-action');
	var Template = Handlebars.compile($(TemplateId).html());
	var TemplateData = Template(Data);

	if((TemplateAction == 'append') || (TemplateAction == 'replace'))
	{
		if (TemplateAction == 'replace') {
			$(ContainerId).empty();
		}

		$(ContainerId).append(TemplateData);
	}

	if(TemplateAction == 'prepend')
	{
		$(ContainerId).prepend(TemplateData);
	}

	if(TemplateAction == 'after')
	{
		$(ContainerId).after(TemplateData);
	}
}