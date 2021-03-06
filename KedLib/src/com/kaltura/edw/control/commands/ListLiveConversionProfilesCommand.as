package com.kaltura.edw.control.commands {
	import com.adobe.cairngorm.control.CairngormEvent;
	import com.kaltura.commands.conversionProfile.ConversionProfileList;
	import com.kaltura.edw.control.commands.KedCommand;
	import com.kaltura.edw.model.datapacks.FlavorsDataPack;
	import com.kaltura.events.KalturaEvent;
	import com.kaltura.kmvc.control.KMvCEvent;
	import com.kaltura.types.KalturaConversionProfileType;
	import com.kaltura.types.KalturaNullableBoolean;
	import com.kaltura.vo.KalturaConversionProfile;
	import com.kaltura.vo.KalturaConversionProfileFilter;
	import com.kaltura.vo.KalturaConversionProfileListResponse;
	import com.kaltura.vo.KalturaFilterPager;
	
	import mx.collections.ArrayCollection;

	[ResourceBundle("live")]
	
	public class ListLiveConversionProfilesCommand extends KedCommand {

		override public function execute(event:KMvCEvent):void {
			
			var p:KalturaFilterPager = new KalturaFilterPager();
			p.pageIndex = 1;
			p.pageSize = 500; // trying to get all conversion profiles here, standard partner has no more than 10
			var f:KalturaConversionProfileFilter = new KalturaConversionProfileFilter();
			f.typeEqual = KalturaConversionProfileType.LIVE_STREAM;
			var listProfiles:ConversionProfileList = new ConversionProfileList(f, p);
			listProfiles.addEventListener(KalturaEvent.COMPLETE, result);
			listProfiles.addEventListener(KalturaEvent.FAILED, fault);
			_model.increaseLoadCounter();
			_client.post(listProfiles);
		}


		override public function result(data:Object):void {
			super.result(data);
			
			var result:Array = new Array();
			for each (var kcp:KalturaConversionProfile in (data.data as KalturaConversionProfileListResponse).objects) {
				if (kcp.isDefault == KalturaNullableBoolean.TRUE_VALUE) {
					result.unshift(kcp);
				}
				else {
					result.push(kcp);
				}
			}
			var fdp:FlavorsDataPack = _model.getDataPack(FlavorsDataPack) as FlavorsDataPack;
			fdp.liveConversionProfiles = new ArrayCollection(result);
			_model.decreaseLoadCounter();

		}
	}
}
