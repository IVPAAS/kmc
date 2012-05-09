package com.kaltura.kmc.modules.content.business
{
	import com.adobe.cairngorm.control.CairngormEvent;
	import com.kaltura.analytics.GoogleAnalyticsConsts;
	import com.kaltura.analytics.GoogleAnalyticsTracker;
	import com.kaltura.analytics.KAnalyticsTracker;
	import com.kaltura.analytics.KAnalyticsTrackerConsts;
	import com.kaltura.edw.business.IDataOwner;
	import com.kaltura.edw.components.playlist.ManualPlaylistWindow;
	import com.kaltura.edw.components.playlist.events.ManualPlaylistWindowEvent;
	import com.kaltura.edw.components.playlist.types.ManualPlaylistWindowMode;
	import com.kaltura.edw.constants.PanelConsts;
	import com.kaltura.edw.control.KedController;
	import com.kaltura.edw.control.events.KedEntryEvent;
	import com.kaltura.edw.control.events.LoadEvent;
	import com.kaltura.edw.control.events.SearchEvent;
	import com.kaltura.edw.events.KedDataEvent;
	import com.kaltura.edw.model.datapacks.ContextDataPack;
	import com.kaltura.edw.model.datapacks.DistributionDataPack;
	import com.kaltura.edw.model.datapacks.EntryDataPack;
	import com.kaltura.edw.model.types.WindowsStates;
	import com.kaltura.edw.view.EntryDetailsWin;
	import com.kaltura.edw.view.window.CategoryBrowser;
	import com.kaltura.edw.view.window.SetEntryOwnerWindow;
	import com.kaltura.edw.vo.ListableVo;
	import com.kaltura.kmc.business.JSGate;
	import com.kaltura.kmc.events.KmcHelpEvent;
	import com.kaltura.kmc.modules.content.events.CategoryEvent;
	import com.kaltura.kmc.modules.content.events.EntriesEvent;
	import com.kaltura.kmc.modules.content.events.KMCEntryEvent;
	import com.kaltura.kmc.modules.content.events.KMCSearchEvent;
	import com.kaltura.kmc.modules.content.events.SetPlaylistTypeEvent;
	import com.kaltura.kmc.modules.content.events.UpdateEntryEvent;
	import com.kaltura.kmc.modules.content.events.WindowEvent;
	import com.kaltura.kmc.modules.content.model.CmsModelLocator;
	import com.kaltura.kmc.modules.content.model.types.EntryDetailsWindowState;
	import com.kaltura.kmc.modules.content.utils.StringUtil;
	import com.kaltura.kmc.modules.content.view.window.AddStream;
	import com.kaltura.kmc.modules.content.view.window.AddTagsWin;
	import com.kaltura.kmc.modules.content.view.window.DownloadWin;
	import com.kaltura.kmc.modules.content.view.window.MoveCategoriesWindow;
	import com.kaltura.kmc.modules.content.view.window.RemoveCategoriesWindow;
	import com.kaltura.kmc.modules.content.view.window.RemoveTagsWin;
	import com.kaltura.kmc.modules.content.view.window.RulePlaylistWindow;
	import com.kaltura.kmc.modules.content.view.window.SetAccessControlProfileWin;
	import com.kaltura.kmc.modules.content.view.window.SetSchedulingWin;
	import com.kaltura.kmc.modules.content.view.window.cdw.CategoryDetailsWin;
	import com.kaltura.kmvc.control.KMvCEvent;
	import com.kaltura.kmvc.model.KMvCModel;
	import com.kaltura.types.KalturaMediaType;
	import com.kaltura.types.KalturaPlaylistType;
	import com.kaltura.types.KalturaStatsKmcEventType;
	import com.kaltura.utils.SoManager;
	import com.kaltura.vo.KalturaBaseEntry;
	import com.kaltura.vo.KalturaCategory;
	import com.kaltura.vo.KalturaLiveStreamAdminEntry;
	import com.kaltura.vo.KalturaLiveStreamBitrate;
	import com.kaltura.vo.KalturaMediaEntry;
	import com.kaltura.vo.KalturaPlaylist;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import modules.Content;
	
	import mx.collections.ArrayCollection;
	import mx.containers.TitleWindow;
	import mx.containers.ViewStack;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;

	
	
	[Event(name="refreshData", type="flash.events.Event")]
	
	
	/**
	 * manages all content popups navigation
	 * @author atar.shadmi
	 * 
	 */	
	public class WindowsManager extends EventDispatcher {
		
		private const DOWNLOAD_FINITE:String = "/file_name/name";
		
		/**
		 * Content's model 
		 */		
		public var model:CmsModelLocator;
		
		/**
		 * reference to Content's view stack 
		 */		
		public var contentView:ViewStack;
		
		
		/**
		 * reference to Content module 
		 */		
		public var owner:Content;
		
		[Bindable]
		/**
		 * entry data
		 * */
		private var _entryData:EntryDataPack = KMvCModel.getInstance().getDataPack(EntryDataPack) as EntryDataPack;		
		
		/**
		 * opens or closes needed popup windows according to new state
		 * */
		public function changeWindowState(newState:String):void {
			if (newState == WindowsStates.NONE) {
				dispatchEvent(new Event("refreshData"));
				closePopup();
				owner.enabled = true;
			}
			else if (newState == WindowsStates.ENTRY_DETAILS_WINDOW_CLOSED_ONE) {
				closePopup();
			}
			else {
				owner.enabled = false;
				var currentPopUp:TitleWindow;
				switch (newState) {
					case WindowsStates.REPLACEMENT_ENTRY_DETAILS_WINDOW:
						currentPopUp = openEntryDetails(EntryDetailsWindowState.REPLACEMENT_ENTRY);
						break;
					case WindowsStates.ENTRY_DETAILS_WINDOW_NEW_ENTRY:
						currentPopUp = openEntryDetails(EntryDetailsWindowState.NEW_ENTRY);
						break;
					case WindowsStates.ENTRY_DETAILS_WINDOW:
						currentPopUp = openEntryDetails(EntryDetailsWindowState.NORMAL_ENTRY);
						break;
					case WindowsStates.PLAYLIST_ENTRY_DETAILS_WINDOW:
						currentPopUp = openEntryDetails(EntryDetailsWindowState.PLAYLIST_ENTRY);
						break;
					case WindowsStates.DOWNLOAD_WINDOW:
						currentPopUp = openDownload();
						break;
					case WindowsStates.ADD_TAGS_WINDOW:
						var atw:AddTagsWin = new AddTagsWin();
						atw.selectedEntries = new ArrayCollection(model.selectedEntries);
						currentPopUp = atw;
						break;
					case WindowsStates.ADD_LIVE_STREAM:
						currentPopUp = new AddStream();
						break;
					case WindowsStates.REMOVE_TAGS_WINDOW:
						currentPopUp = new RemoveTagsWin();
						(currentPopUp as RemoveTagsWin).selectedEntries = new ArrayCollection(model.selectedEntries);
						break;
					case WindowsStates.PLAYLIST_MANUAL_WINDOW:
						currentPopUp = openManualPlaylist();
						break;
					case WindowsStates.PLAYLIST_RULE_BASED_WINDOW:
						currentPopUp = openRuleBasedPlaylist();
						break;
					case WindowsStates.SETTING_ACCESS_CONTROL_PROFILES_WINDOW:
						currentPopUp = new SetAccessControlProfileWin();
						(currentPopUp as SetAccessControlProfileWin).selectedEntries = new ArrayCollection(model.selectedEntries);
						(currentPopUp as SetAccessControlProfileWin).filterModel = model.filterModel;
						(currentPopUp as SetAccessControlProfileWin).entryDetailsModel = KMvCModel.getInstance();
						
						break;
					case WindowsStates.SETTING_SCHEDULING_WINDOW:
						currentPopUp = new SetSchedulingWin();
						(currentPopUp as SetSchedulingWin).selectedEntries = new ArrayCollection(model.selectedEntries);
						break;
					case WindowsStates.PREVIEW:
						openPreviewEmbed();
						break;
					case WindowsStates.CATEGORY_DETAILS_WINDOW:
						var catDetails:CategoryDetailsWin;
						currentPopUp = catDetails = new CategoryDetailsWin();
						var selectedCat:KalturaCategory = model.categoriesModel.selectedCategories[0] as KalturaCategory;
						if (selectedCat.name == null){
							model.categoriesModel.processingNewCategory = true;	//TODO make pretty
							catDetails.isNewCategory = true;
						}
						catDetails.filterModel = model.filterModel;
						catDetails.categoriesModel = model.categoriesModel;
						catDetails.addEventListener(KedDataEvent.CLOSE_WINDOW, handleKedEvents, false, 0, true);
						break;
					case WindowsStates.CHANGE_ENTRY_OWNER_WINDOW:
						currentPopUp = new SetEntryOwnerWindow();
						currentPopUp.addEventListener("save", handleChangeEntryOwnerEvents, false, 0, true);
						currentPopUp.addEventListener(CloseEvent.CLOSE, handleChangeEntryOwnerEvents, false, 0, true);
						(currentPopUp as SetEntryOwnerWindow).kClient = (KMvCModel.getInstance().getDataPack(ContextDataPack) as ContextDataPack).kc;
						//							(currentPopUp as SetOwnerWindow).entryData = _entryData;
						//							(currentPopUp as SetOwnerWindow).setUserById(_entryData.selectedEntry.userId);
						break;
					case WindowsStates.ADD_CATEGORIES_WINDOW:
						currentPopUp = new CategoryBrowser();
						currentPopUp.addEventListener("apply", handleAddCategoriesEvents, false, 0, true);
						currentPopUp.addEventListener(CloseEvent.CLOSE, handleAddCategoriesEvents, false, 0, true);
						(currentPopUp as CategoryBrowser).filterModel = model.filterModel;
						(currentPopUp as CategoryBrowser).kClient = (KMvCModel.getInstance().getDataPack(ContextDataPack) as ContextDataPack).kc;
						break;
					case WindowsStates.REMOVE_CATEGORIES_WINDOW:
						currentPopUp = new RemoveCategoriesWindow();
						currentPopUp.addEventListener("apply", handleRemoveCategoriesEvents, false, 0, true);
						currentPopUp.addEventListener(CloseEvent.CLOSE, handleRemoveCategoriesEvents, false, 0, true);
						(currentPopUp as RemoveCategoriesWindow).model = model;
						break;
					case WindowsStates.MOVE_CATEGORIES_WINDOW:
						currentPopUp = new MoveCategoriesWindow();
						currentPopUp.addEventListener("apply", handleMoveCategoriesEvents, false, 0, true);
						currentPopUp.addEventListener(CloseEvent.CLOSE, handleMoveCategoriesEvents, false, 0, true);
						(currentPopUp as MoveCategoriesWindow).filterModel = model.filterModel;
						(currentPopUp as MoveCategoriesWindow).setCategories(model.categoriesModel.selectedCategories);
						break;
				}
				
				// add the new window
				if (currentPopUp) {
					addPopup(currentPopUp);
					// if this is a replacement entry drilldown, move it a little
					if (newState == WindowsStates.REPLACEMENT_ENTRY_DETAILS_WINDOW) {
						currentPopUp.x += 20;
						currentPopUp.y += 40;
					}
				}
			}
		}
		
		
		/**
		 * adds a popup window to the screen
		 * */
		private function addPopup(currentPopUp:TitleWindow):void {
			currentPopUp.addEventListener(KmcHelpEvent.HELP, onHelp, false, 0, true);
			// remember the new window
			model.popups.push(currentPopUp);
			if (model.popups.length == 1) {
				// this is the first popup
				owner.pEnableHtmlTabs(false);
				
			}
			PopUpManager.addPopUp(currentPopUp, Application.application as DisplayObject, true);
			currentPopUp.setFocus();
			centerPopups();
		}
		
		
		/**
		 * close popup window.
		 * if this was the last opened popup, enable HTML tabs
		 * */
		private function closePopup():void {
			var popup:TitleWindow = model.topPopup;
			if (popup) {
				popup.removeEventListener(KmcHelpEvent.HELP, onHelp, false);
				PopUpManager.removePopUp(popup);
				model.popups.pop();
			}
			if (!model.topPopup) {
				if (popup) {
					// only do this if we actualy closed a popup
					owner.pEnableHtmlTabs(true);
					if (contentView) {
						contentView.selectedChild.setFocus();
					}
				}
			}
		}
		
		/**
		 * bring any visible popups to the center of the screen
		 * */
		public function centerPopups(event:Event = null):void {
			for (var i:int = 0; i < model.popups.length; i++) {
				PopUpManager.centerPopUp(model.popups[i]);
			}
		}
		
		
		private function onHelp(e:KmcHelpEvent):void {
			dispatchEvent(new KmcHelpEvent(KmcHelpEvent.HELP, e.anchor));
		}
		
		/**
		 * allows download of a single image or opens a download popup window
		 * */
		private function openDownload():DownloadWin {
			var dw:DownloadWin;
			//if the user selected to download a single image, no need to open to pop-up
			if ((model.selectedEntries) && (model.selectedEntries.length == 1) && 
				(model.selectedEntries[0] is KalturaMediaEntry) && 
				((model.selectedEntries[0] as KalturaMediaEntry).mediaType == KalturaMediaType.IMAGE)) {
				var urlRequest:URLRequest = new URLRequest(model.selectedEntries[0].downloadUrl + DOWNLOAD_FINITE);
				navigateToURL(urlRequest);
				owner.enabled = true;
			}
			else {
				dw = new DownloadWin();
				dw.entries = model.selectedEntries;
				dw.flavorParams = model.filterModel.flavorParams;
			}
			return dw;
		}
		
		/**
		 * opens a popup window with entry details
		 * @param state	they type of entry drilldown to show, enumerated in <code>EntryDetailsWindowState</code>
		 * */
		private function openEntryDetails(state:String):EntryDetailsWin {
			var edw:EntryDetailsWin = new EntryDetailsWin();
			edw.styleName = "WinTitleStyle";
			edw.addEventListener(KedDataEvent.ENTRY_RELOADED, handleKedEvents, false, 0, true);
			edw.addEventListener(KedDataEvent.CLOSE_WINDOW, handleKedEvents, false, 0, true);
			edw.addEventListener(KedDataEvent.CATEGORY_CHANGED, handleKedEvents, false, 0, true);
			edw.addEventListener(KedDataEvent.ENTRY_UPDATED, handleKedEvents, false, 0, true);
			edw.addEventListener(KedDataEvent.OPEN_REPLACEMENT, handleKedEvents, false, 0, true);
			edw.addEventListener(KedDataEvent.OPEN_ENTRY, handleKedEvents, false, 0, true);
			edw.isNewEntry = state == EntryDetailsWindowState.NEW_ENTRY;
			//get the selected entry from the server
			if (state != EntryDetailsWindowState.NEW_ENTRY) {
				var getSelectedEntry:KedEntryEvent = new KedEntryEvent(KedEntryEvent.UPDATE_SELECTED_ENTRY_REPLACEMENT_STATUS, null,
					_entryData.selectedEntry.id);
				KedController.getInstance().dispatch(getSelectedEntry);
			}
			if (state == EntryDetailsWindowState.REPLACEMENT_ENTRY) {
				setReplacementDrilldown(edw);
			}
			
			var entryDetailsModel:KMvCModel = KMvCModel.getInstance();
			edw.entryDetailsModel = entryDetailsModel;
			var contextData:ContextDataPack = entryDetailsModel.getDataPack(ContextDataPack) as ContextDataPack;
			contextData.showEmbedCode = model.showSingleEntryEmbedCode;
			contextData.landingPage = model.extSynModel.partnerData.landingPage;
			contextData.openPlayerFunc = model.openPlayer;
			if (state != EntryDetailsWindowState.NORMAL_ENTRY)
				edw.showNextPrevBtns = false;
			else if (model.listableVo)	// only for normal entries
				edw.itemsAC = model.listableVo.arrayCollection;
			GoogleAnalyticsTracker.getInstance().sendToGA(GoogleAnalyticsConsts.CONTENT_ENTRY_DRILLDOWN, GoogleAnalyticsConsts.CONTENT)
			KAnalyticsTracker.getInstance().sendEvent(KAnalyticsTrackerConsts.CONTENT, KalturaStatsKmcEventType.CONTENT_ENTRY_DRILLDOWN, "content>Entry DrillDown");
			
			return edw;
		
		}
		
		
		/**
		 * open drill down to replacement entry, with partial tabs list
		 * */
		private function setReplacementDrilldown(edw:EntryDetailsWin):void {
			KMvCModel.addModel();
			var edp:EntryDataPack = KMvCModel.getInstance().getDataPack(EntryDataPack) as EntryDataPack;
			edp.selectedEntry = _entryData.selectedReplacementEntry;
			edp.replacedEntryName = _entryData.selectedEntry.name;
			//
			edp.loadRoughcuts = false;
			//				edw.showNextPrevBtns = false;
			edw.visibleTabs = Vector.<String>([PanelConsts.ASSETS_PANEL]);
			edw.styleName = "WinTitleStyle2";
			edw.setStyle("modalTransparency", 0);
		}
		
		
		/**
		 * start the sequence of commands which will end in opening drilldown
		 * window for the given entry.
		 * @param entry		the entry to drill into.
		 * */
		private function requestEntryDrilldown(entry:KalturaBaseEntry):void {
			var cgEvent:CairngormEvent;
			var kEvent:KMvCEvent = new KedEntryEvent(KedEntryEvent.SET_SELECTED_ENTRY, entry);
			KedController.getInstance().dispatch(kEvent);
			if (entry is KalturaPlaylist) {
				//switch manual / rule base
				if ((entry as KalturaPlaylist).playlistType == KalturaPlaylistType.STATIC_LIST) {
					// manual list
					cgEvent = new WindowEvent(WindowEvent.OPEN, WindowsStates.PLAYLIST_MANUAL_WINDOW);
					cgEvent.dispatch();
				}
				if ((entry as KalturaPlaylist).playlistType == KalturaPlaylistType.DYNAMIC) {
					cgEvent = new WindowEvent(WindowEvent.OPEN, WindowsStates.PLAYLIST_RULE_BASED_WINDOW);
					cgEvent.dispatch();
				}
			}
			else {
				cgEvent = new WindowEvent(WindowEvent.OPEN, WindowsStates.ENTRY_DETAILS_WINDOW);
				cgEvent.dispatch();
			}
		}

		
		
		/**
		 * handle events dispatched by the drilldown
		 * */
		public function handleKedEvents(e:KedDataEvent):void {
			switch (e.type) {
				
				case KedDataEvent.ENTRY_UPDATED:
					// set refresh list required
					model.refreshEntriesRequired = true;
					// break; // case falldown
				case KedDataEvent.ENTRY_RELOADED:
					// dispatch a Cairngorm event which will update the new entry in the entries list
					var uev:UpdateEntryEvent = new UpdateEntryEvent(UpdateEntryEvent.UPDATE_ENTRY_IN_LIST);
					uev.data = e.data;
					uev.dispatch();
					break;
				
				case KedDataEvent.CLOSE_WINDOW:
					// close the drilldown
					var cgEvent:CairngormEvent = new WindowEvent(WindowEvent.CLOSE);
					cgEvent.dispatch();
					
					// make sure list is refreshed when drilldown window is closed
					if (model.refreshEntriesRequired) {
						cgEvent = new KMCSearchEvent(KMCSearchEvent.DO_SEARCH_ENTRIES, model.listableVo);
						cgEvent.dispatch();
					}
					break;
				
				case KedDataEvent.CATEGORY_CHANGED:
					// list entries
					var searchEvent:KMCSearchEvent = new KMCSearchEvent(KMCSearchEvent.DO_SEARCH_ENTRIES , model.listableVo  );
					searchEvent.dispatch();
					break;
				
				case KedDataEvent.OPEN_REPLACEMENT:
					var openWindow:WindowEvent = new WindowEvent(WindowEvent.OPEN, WindowsStates.REPLACEMENT_ENTRY_DETAILS_WINDOW);
					openWindow.dispatch();
					break;
				
				case KedDataEvent.OPEN_ENTRY:
					requestEntryDrilldown(e.data);
					break;
			}
		}
		
		
		/**
		 * opens a popup window with manual playlist
		 * */
		private function openManualPlaylist():ManualPlaylistWindow {
			var cgEvent:EntriesEvent = new EntriesEvent(EntriesEvent.SET_SELECTED_ENTRIES_FOR_PLAYLIST);
			cgEvent.dispatch();
			
			var mpw:ManualPlaylistWindow = new ManualPlaylistWindow();
			mpw.rootUrl = model.context.rootUrl;
			mpw.filterData = model.filterModel;
			
			if (model.playlistModel.onTheFlyPlaylistType == SetPlaylistTypeEvent.MANUAL_PLAYLIST) {
				// this is not an empty or edit existing playlist - this is a
				// new playlist created on the fly from entries screen 
				mpw.onTheFlyEntries = model.playlistModel.onTheFlyPlaylistEntries;
			}	
			
			mpw.distributionProfilesArray = (model.entryDetailsModel.getDataPack(DistributionDataPack) as DistributionDataPack).distributionProfileInfo.kalturaDistributionProfilesArray;
			mpw.selectedEntry = _entryData.selectedEntry;
			if (_entryData.selectedEntry && _entryData.selectedEntry.id){
				mpw.context = ManualPlaylistWindowMode.EDIT_PLAYLIST_MODE;
			}
			
			mpw.addEventListener(ManualPlaylistWindowEvent.CLOSE, handleManPlEvents);
			mpw.addEventListener(ManualPlaylistWindowEvent.SHOW_ENTRY_DETAILS, handleManPlEvents);
			mpw.addEventListener(ManualPlaylistWindowEvent.SAVE_NEW_PLAYLIST, handleManPlEvents);
			mpw.addEventListener(ManualPlaylistWindowEvent.SAVE_EXISTING_PLAYLIST, handleManPlEvents);
			mpw.addEventListener(ManualPlaylistWindowEvent.GET_PLAYLIST, handleManPlEvents);
			mpw.addEventListener(ManualPlaylistWindowEvent.LOAD_FILTER_DATA, handleManPlEvents);
			mpw.addEventListener(ManualPlaylistWindowEvent.SEARCH_ENTRIES, handleManPlEvents);
			return mpw;
		}
		
		
		private function handleManPlEvents(e:ManualPlaylistWindowEvent) :void {
			var cgEvent:CairngormEvent;
			switch (e.type) {
				case ManualPlaylistWindowEvent.CLOSE:
					var mpw:ManualPlaylistWindow = e.target as ManualPlaylistWindow;
					mpw.removeEventListener(ManualPlaylistWindowEvent.CLOSE, handleManPlEvents);
					mpw.removeEventListener(ManualPlaylistWindowEvent.SHOW_ENTRY_DETAILS, handleManPlEvents);
					mpw.removeEventListener(ManualPlaylistWindowEvent.SAVE_NEW_PLAYLIST, handleManPlEvents);
					mpw.removeEventListener(ManualPlaylistWindowEvent.SAVE_EXISTING_PLAYLIST, handleManPlEvents);
					mpw.removeEventListener(ManualPlaylistWindowEvent.GET_PLAYLIST, handleManPlEvents);
					mpw.removeEventListener(ManualPlaylistWindowEvent.LOAD_FILTER_DATA, handleManPlEvents);
					mpw.removeEventListener(ManualPlaylistWindowEvent.SEARCH_ENTRIES, handleManPlEvents);
					// reset on-the-fly flag 
					cgEvent = new SetPlaylistTypeEvent(SetPlaylistTypeEvent.NONE_PLAYLIST);
					cgEvent.dispatch();
					cgEvent = new WindowEvent(WindowEvent.CLOSE);
					cgEvent.dispatch();
					break;
				
				case ManualPlaylistWindowEvent.SHOW_ENTRY_DETAILS:
					// open entry details window with the selected entry from the playlist
					var entry:KalturaBaseEntry = e.data as KalturaBaseEntry;
					var kEvent:KMvCEvent = new KedEntryEvent(KedEntryEvent.SET_SELECTED_ENTRY, entry, entry.id);
					KedController.getInstance().dispatch(kEvent);
					cgEvent = new WindowEvent(WindowEvent.OPEN, WindowsStates.PLAYLIST_ENTRY_DETAILS_WINDOW);
					cgEvent.dispatch();
					break;
				
				case ManualPlaylistWindowEvent.SAVE_NEW_PLAYLIST:
					var addEntryEvent:KMCEntryEvent = new KMCEntryEvent(KMCEntryEvent.ADD_PLAYLIST, e.data as KalturaPlaylist);
					addEntryEvent.dispatch();
					break;
				
				case ManualPlaylistWindowEvent.SAVE_EXISTING_PLAYLIST:
					var entriesEvent:EntriesEvent = new EntriesEvent(EntriesEvent.UPDATE_PLAYLISTS,
						new ArrayCollection([e.data as KalturaPlaylist]));
					entriesEvent.dispatch();
					break;
				
				case ManualPlaylistWindowEvent.GET_PLAYLIST:
					cgEvent = new KMCEntryEvent(KMCEntryEvent.GET_PLAYLIST, e.data as KalturaPlaylist);
					cgEvent.dispatch();
					break;
				
				case ManualPlaylistWindowEvent.LOAD_FILTER_DATA:
					var fe:LoadEvent = new LoadEvent(LoadEvent.LOAD_FILTER_DATA, e.target as IDataOwner, model.filterModel);
					KedController.getInstance().dispatch(fe);
					break;
				
				case ManualPlaylistWindowEvent.SEARCH_ENTRIES:
					var searchEvent:SearchEvent = new SearchEvent(SearchEvent.SEARCH_ENTRIES, e.data as ListableVo);
					KedController.getInstance().dispatch(searchEvent);
					break;
			}
		}
		
		
		
		/**
		 * opens a popup window with rule based playlist
		 * */
		private function openRuleBasedPlaylist():RulePlaylistWindow {
			var rpw:RulePlaylistWindow = new RulePlaylistWindow();
			rpw.rulePlaylistData = model.playlistModel;
			rpw.rootUrl = model.context.rootUrl;
			if (_entryData.selectedEntry && (_entryData.selectedEntry is KalturaPlaylist)) {
				rpw.editPlaylist = _entryData.selectedEntry as KalturaPlaylist;
			}
			rpw.filterData = model.filterModel;
			
			rpw.distributionProfilesArr = (model.entryDetailsModel.getDataPack(DistributionDataPack) as DistributionDataPack).distributionProfileInfo.kalturaDistributionProfilesArray;
			// assign the current fiter to the new window 
			rpw.onTheFlyFilter = model.playlistModel.onTheFlyFilter;
			model.playlistModel.onTheFlyFilter = null;
			return rpw;
		}
		
		/**
		 * open a preview player with live streaming entry
		 * */
		private function openLivestreamPreview(entry:KalturaBaseEntry):void {
			var lp:KalturaLiveStreamAdminEntry = entry as KalturaLiveStreamAdminEntry;
			var bitrates:Array = new Array();
			var o:Object;
			for each (var br:KalturaLiveStreamBitrate in lp.bitrates) {
				o = new Object();
				o.bitrate = br.bitrate;
				o.width = br.width;
				o.height = br.height;
				bitrates.push(o);
			}
			
			if (model.openPlayer) {
				//id, name, description, previewonly, is_playlist, uiconf_id 
				JSGate.doPreviewEmbed(model.openPlayer, lp.id, lp.name, StringUtil.cutTo512Chars(lp.description), !model.showSingleEntryEmbedCode, false, model.attic.previewuiconf, bitrates, [], false);
				model.attic.previewuiconf = null;
			}
			
			//First time funnel
			if (!SoManager.getInstance().checkOrFlush(GoogleAnalyticsConsts.CONTENT_FIRST_TIME_PLAYER_EMBED)) {
				GoogleAnalyticsTracker.getInstance().sendToGA(GoogleAnalyticsConsts.CONTENT_FIRST_TIME_PLAYER_EMBED, GoogleAnalyticsConsts.CONTENT);
			}
		}
		
		
		/**
		 * open a preview player with playlist
		 * */
		private function openPlaylistPreview(entry:KalturaBaseEntry):void {
			// open playlist preview
			if (model.openPlaylist) {
				var pl:KalturaPlaylist = entry as KalturaPlaylist;
				JSGate.doPreviewEmbed(model.openPlaylist, pl.id, pl.name, StringUtil.cutTo512Chars(pl.description), !model.showPlaylistEmbedCode, true, model.attic.previewuiconf, null, [], false);
				model.attic.previewuiconf = null;
				//first time funnel 
				if (!SoManager.getInstance().checkOrFlush(GoogleAnalyticsConsts.CONTENT_FIRST_TIME_PLAYLIST_EMBED)) {
					GoogleAnalyticsTracker.getInstance().sendToGA(GoogleAnalyticsConsts.CONTENT_FIRST_TIME_PLAYLIST_EMBED, GoogleAnalyticsConsts.CONTENT);
				}
			}
		}
		
		
		/**
		 * open a preview player with a normal entry
		 * */
		private function openEntryPreview(entry:KalturaBaseEntry):void {
			// open regular entry preview
			if (model.openPlayer) {
				var cgEvent:KMCEntryEvent = new KMCEntryEvent(KMCEntryEvent.GET_FLAVOR_ASSETS_FOR_PREVIEW, entry);
				cgEvent.dispatch();
			}
			//First time funnel
			if (!SoManager.getInstance().checkOrFlush(GoogleAnalyticsConsts.CONTENT_FIRST_TIME_PLAYER_EMBED)) {
				GoogleAnalyticsTracker.getInstance().sendToGA(GoogleAnalyticsConsts.CONTENT_FIRST_TIME_PLAYER_EMBED, GoogleAnalyticsConsts.CONTENT);
			}
		}
		
		
		/**
		 * Open a preview player. <br>
		 * This method triggers one of the specific openPreview methods.
		 * */
		private function openPreviewEmbed():void {
			var entry:KalturaBaseEntry = _entryData.selectedEntry;
			
			if (entry is KalturaLiveStreamAdminEntry) {
				openLivestreamPreview(entry);
				
			}
			else if (entry is KalturaPlaylist) {
				openPlaylistPreview(entry);
			}
			else {
				openEntryPreview(entry);
			}
			model.windowState = WindowsStates.NONE;
		}

		
		private function handleChangeEntryOwnerEvents(e:Event):void {
			switch (e.type) {
				case "save":
					// set entry owner for all selected entries
					var tgt:SetEntryOwnerWindow = e.target as SetEntryOwnerWindow;
					var kEvent:EntriesEvent = new EntriesEvent(EntriesEvent.SET_ENTRIES_OWNER, new ArrayCollection(model.selectedEntries));
					kEvent.data = tgt.selectedUser.id;
					kEvent.dispatch();
					break;
				case CloseEvent.CLOSE:
					// close the popup
					var cgEvent:WindowEvent = new WindowEvent(WindowEvent.CLOSE);
					cgEvent.dispatch();
					break;
			}
		}
		
		
		private function handleAddCategoriesEvents(e:Event):void {
			switch (e.type) {
				case "apply":
					// add categories to all selected entries
					var tgt:CategoryBrowser = e.target as CategoryBrowser;
					var kEvent:EntriesEvent = new EntriesEvent(EntriesEvent.ADD_CATEGORIES_ENTRIES, new ArrayCollection(model.selectedEntries));
					kEvent.data = tgt.getCategories();
					kEvent.dispatch();
					break;
				case CloseEvent.CLOSE:
					// close the popup
					var cgEvent:WindowEvent = new WindowEvent(WindowEvent.CLOSE);
					cgEvent.dispatch();
					break;
			}
		}
		
		
		
		private function handleRemoveCategoriesEvents(e:Event):void {
			switch (e.type) {
				//					case "apply": (handled inside the window)
				//						break;
				case CloseEvent.CLOSE:
					// close the popup
					var cgEvent:WindowEvent = new WindowEvent(WindowEvent.CLOSE);
					cgEvent.dispatch();
					break;
			}
		}

		
		
		
		private function handleMoveCategoriesEvents(e:Event):void {
			switch (e.type) {
				case "apply": 
					// set all categories as children of the selected parent category 
					var tgt:MoveCategoriesWindow = e.target as MoveCategoriesWindow;
					var kEvent:CategoryEvent = new CategoryEvent(CategoryEvent.MOVE_CATEGORIES);
					kEvent.data = [tgt.getCategories(), tgt.getParent()];
					kEvent.dispatch();
					break;
				case CloseEvent.CLOSE:
					// close the popup
					var cgEvent:WindowEvent = new WindowEvent(WindowEvent.CLOSE);
					cgEvent.dispatch();
					break;
			}
		}
		
		
	}
}