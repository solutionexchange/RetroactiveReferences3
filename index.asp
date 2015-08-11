<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="expires" content="-1"/>
	<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
	<meta name="copyright" content="2014, Web Solutions"/>
	<meta http-equiv="X-UA-Compatible" content="IE=edge" >
	<title>Retroactive References 3</title>
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
	<script type="text/javascript" src="js/jquery-1.10.2.min.js"></script>
	<script type="text/javascript" src="js/bootstrap.min.js"></script>
	<script type="text/javascript" src="js/handlebars-v2.0.0.js"></script>
	<script type="text/javascript" src="js/retroactive-references.js"></script>
	<script type="text/javascript" src="rqlconnector/Rqlconnector.js"></script>
	
	<script id="template-source" type="text/x-handlebars-template" data-container="#source" data-action="replace">
		<div class="alert alert-success element" data-guid="{{guid}}" data-name="{{name}}" data-type="{{type}}" data-tree-type="{{treetype}}" data-content-class-guid="{{contentclassguid}}">
			<img src="{{icon}}" /> {{name}}
		</div>
	</script>
	
	<script id="template-source-error" type="text/x-handlebars-template" data-container="#source" data-action="replace">
		<div class="alert alert-error element">
			{{name}}
		</div>
	</script>
	
	<script id="template-target" type="text/x-handlebars-template" data-container="#target" data-action="replace">
		<div class="alert alert-success element" data-guid="{{guid}}" data-name="{{name}}" data-type="{{type}}" data-tree-type="{{treetype}}">
			<img src="{{icon}}" /> {{name}}
		</div>
	</script>
	
	<script id="template-target-error" type="text/x-handlebars-template" data-container="#target" data-action="replace">
		<div class="alert alert-error element">
			{{name}}
		</div>
	</script>
	
	<script id="template-pre-reference-in-template" type="text/x-handlebars-template" data-container="#pre-reference-in-template" data-action="replace">
		<div class="element" data-guid="{{guid}}" >
			<label class="checkbox">
				<input type="checkbox"  checked="checked"> Preassign reference in template (apply to all future pages)
			</label>
		</div>
	</script>
	
	<script id="template-status" type="text/x-handlebars-template" data-container="#status" data-action="replace">
		<div class="alert {{css}}">
			{{message}}
		</div>
	</script>
	
	<script id="template-type-mismatch" type="text/x-handlebars-template" data-container="#processing" data-action="replace">
		<div class="alert alert-error">
			Item types do not match
		</div>
	</script>
	
	<script id="template-processing-all-complete" type="text/x-handlebars-template" data-container="#processing" data-action="replace">
		<div class="alert alert-success">
			All processing completed
		</div>
	</script>
	
	<script id="template-processing-status" type="text/x-handlebars-template" data-container="#processing" data-action="append">
		<div class="{{guid}}">
			<div class="alert">
				<strong>Processing:</strong> {{name}}
			</div>
		</div>
	</script>
	
	<script id="template-processing-status-clear" type="text/x-handlebars-template" data-container="#processing" data-action="replace">
	</script>
	
	<script type="text/javascript">
		var LoginGuid = '<%= session("loginguid") %>';
		var SessionKey = '<%= session("sessionkey") %>';
		var ContentClassElementGuid = '<%= session("treeguid") %>';
		var ContentClassElementTreeType = '<%= session("TreeType") %>';
		var ThreadCount = 5;

		$(document).ready(function() {
			var RqlConnectorObj = new RqlConnector(LoginGuid, SessionKey);
			var RetroactiveReferencesObj = new RetroactiveReferences(RqlConnectorObj, ContentClassElementGuid, ContentClassElementTreeType, ThreadCount);
		});
	</script>
</head>
<body>
	<div id="reference-option-dialog" class="modal hide fade" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
		<div class="modal-header">
			<h4>Reference Item In Clipboard For All Page Instances</h4>
		</div>
		<div class="modal-body">
			<div class="row-fluid">
				<div class="span6">
					<h5>Selected Item</h5>
					<div id="source">
						<div class="alert">Load...</div>
					</div>
				</div>
				<div class="span6">
					<h5>Item to be Referenced</h5>
					<div id="target">
						<div class="alert">Load...</div>
					</div>
				</div>
			</div>
			<div id="pre-reference-in-template">
			</div>
			<br />
			<div class="alert">
				<strong>Warning: </strong>
				This action will be applied to the selected link element in all page instances of this Content Class. Any existing references and connected pages will be replaced.
			</div>
			<div id="status"></div>
		</div>
		<div class="modal-footer">
			<span class="btn btn-success" id="reference-button">Reference</span>
		</div>
	</div>
	<div id="processing">
	</div>
	<div id="thread-temnplate" style="display: none;">
		<div class="thread alert"></div>
	</div>
</body>
</html>