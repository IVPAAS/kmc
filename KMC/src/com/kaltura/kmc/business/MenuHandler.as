package com.kaltura.kmc.business {
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	import modules.AddEntryPanel;
	
	import mx.core.Application;
	import mx.managers.PopUpManager;
	import mx.modules.Module;

	/**
	 * this class is responsible for the visual aspecs of the add menu 
	 * (creating, showing, hiding and positioning..) 
	 * @author Atar
	 */	
	public class MenuHandler implements IPopupMenu {
		
		
		protected var _approot:DisplayObjectContainer;


		/**
		 * the menu panel 
		 */
		protected var _panel:Module;

		/**
		 * @param panel 	the flex module to handle
		 * @param positionJsCallback	name of JS method that positions the panel
		 */
		public function MenuHandler(panel:Module, positionJsCallback:String) {
			_panel = panel;
			ExternalInterface.addCallback(positionJsCallback, positionPanel);
		}
		
		public function setRoot(doc:DisplayObjectContainer):void {
			_approot = doc;
		}
		
		/**
		 * Position will be determined by triggering a JS function (via JSGate) – 
		 * getPanelPosition(). 
		 * Add a stage listener to hide the popup. 
		 */
		public function showPanel():void {
				
			PopUpManager.addPopUp(_panel, _approot);
			positionPanel(JSGate.getPanelPosition());
			
			// add stage listener
			(Application.application as DisplayObjectContainer).addEventListener(MouseEvent.MOUSE_OVER, hidePanel);
		}
		
					
		/**
		 * Remove stage listener and hide the popup. 
		 */
		public function hidePanel(me:MouseEvent = null):void {
			if (_panel && _panel.parent) {
				PopUpManager.removePopUp(_panel);
				// remove stage listener
				(Application.application as DisplayObjectContainer).removeEventListener(MouseEvent.MOUSE_OVER, hidePanel);
			}
		}
		
		/**
		 * An externalInterface method that will allow HTML to position the menu. 
		 * @param right
		 */
		public function positionPanel(right:Number):void {
			_panel.x = right - _panel.width;
			_panel.y = 0;
		}
		
	}
}