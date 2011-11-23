package com.kaltura.edw.control.commands.customData
{
	import com.kaltura.commands.metadata.MetadataList;
	import com.kaltura.edw.business.FormBuilder;
	import com.kaltura.edw.control.commands.KedCommand;
	import com.kaltura.edw.model.FilterModel;
	import com.kaltura.edw.model.datapacks.CustomDataDataPack;
	import com.kaltura.edw.model.datapacks.EntryDataPack;
	import com.kaltura.edw.model.datapacks.FilterDataPack;
	import com.kaltura.edw.vo.EntryMetadataDataVO;
	import com.kaltura.events.KalturaEvent;
	import com.kaltura.kmvc.control.KMvCEvent;
	import com.kaltura.vo.KMCMetadataProfileVO;
	import com.kaltura.vo.KalturaFilterPager;
	import com.kaltura.vo.KalturaMetadata;
	import com.kaltura.vo.KalturaMetadataFilter;
	import com.kaltura.vo.KalturaMetadataListResponse;
	
	import mx.collections.ArrayCollection;
	
	/**
	 * This class sends a metadata data list request to the server and handles the response 
	 * @author Michal
	 * 
	 */	
	public class ListMetadataDataCommand extends KedCommand
	{
		
		private var _filterModel:FilterModel;
		
		/**
		 * This command requests the server for the latest valid metadata data, that suits
		 * the current profile id and current profile version
		 * @param event the event that triggered this command
		 * 
		 */		
		override public function execute(event:KMvCEvent):void
		{
			_filterModel = (_model.getDataPack(FilterDataPack) as FilterDataPack).filterModel;
			var edp:EntryDataPack = _model.getDataPack(EntryDataPack) as EntryDataPack;
			if (!_filterModel.metadataProfiles || !edp.selectedEntry.id)
				return;

			
			var filter:KalturaMetadataFilter = new KalturaMetadataFilter();
			filter.objectIdEqual = edp.selectedEntry.id;	
			var pager:KalturaFilterPager = new KalturaFilterPager();
		
			var listMetadataData:MetadataList = new MetadataList(filter, pager);
			listMetadataData.addEventListener(KalturaEvent.COMPLETE, result);
			listMetadataData.addEventListener(KalturaEvent.FAILED, fault);
			
			_client.post(listMetadataData);
		}
		
		/**
		 * This function handles the response returned from the server 
		 * @param data the data returned from the server
		 * 
		 */		
		override public function result(data:Object):void
		{
			super.result(data);
			var metadataResponse:KalturaMetadataListResponse = data.data as KalturaMetadataListResponse;
			var cddp:CustomDataDataPack = _model.getDataPack(CustomDataDataPack) as CustomDataDataPack;
			cddp.metadataInfoArray = new ArrayCollection;
			//go over all profiles and match to the metadata data
			for (var i:int = 0; i<_filterModel.metadataProfiles.length; i++) {
				var curMetadata:EntryMetadataDataVO = new EntryMetadataDataVO(); 
				cddp.metadataInfoArray.addItem(curMetadata);
				var curFormBuilder:FormBuilder = _filterModel.formBuilders[i] as FormBuilder;
				curFormBuilder.metadataInfo = curMetadata;
				var curProfile:KMCMetadataProfileVO = _filterModel.metadataProfiles[i] as KMCMetadataProfileVO;
				for each (var metadata:KalturaMetadata in metadataResponse.objects) {
					if ((metadata.metadataProfileId == curProfile.profile.id) &&
						(metadata.metadataProfileVersion == curProfile.profile.version)) {
						curMetadata.metadata = metadata;
						break;
					}
				}
				curFormBuilder.updateMultiTags();
			}
		}
		
//		/**
//		 * this function will be called if the request failed 
//		 * @param info the info returned from the server
//		 * 
//		 */		
//		public function fault(info:Object):void
//		{
//			if(info && info.error && info.error.errorMsg && info.error.errorMsg.toString().indexOf("Invalid KS") > -1 )
//			{
//				JSGate.expired();
//				return;
//			}
//			_model.decreaseLoadCounter();
//			Alert.show(info.error.errorMsg, ResourceManager.getInstance().getString('cms', 'error'));
//		}

	}
}