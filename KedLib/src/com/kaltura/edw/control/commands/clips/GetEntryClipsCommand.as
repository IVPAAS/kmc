package com.kaltura.edw.control.commands.clips
{
	import com.kaltura.commands.baseEntry.BaseEntryList;
	import com.kaltura.edw.control.commands.KedCommand;
	import com.kaltura.edw.model.datapacks.ClipsDataPack;
	import com.kaltura.events.KalturaEvent;
	import com.kaltura.kmvc.control.KMvCEvent;
	import com.kaltura.vo.KalturaBaseEntryFilter;
	import com.kaltura.vo.KalturaBaseEntryListResponse;
	
	public class GetEntryClipsCommand extends KedCommand {
		
		
		
		override public function execute(event:KMvCEvent):void {
			_model.increaseLoadCounter();
			var f:KalturaBaseEntryFilter = new KalturaBaseEntryFilter();
			f.rootEntryIdEqual = event.data.id;
			
			var list:BaseEntryList = new BaseEntryList(f, event.data.pager);
			list.addEventListener(KalturaEvent.COMPLETE, result);
			list.addEventListener(KalturaEvent.FAILED, fault);
			_client.post(list);
		}
		
		override public function result(data:Object):void {
			super.result(data);
			(_model.getDataPack(ClipsDataPack) as ClipsDataPack).clips = (data.data as KalturaBaseEntryListResponse).objects;
			_model.decreaseLoadCounter();
		}
	}
}