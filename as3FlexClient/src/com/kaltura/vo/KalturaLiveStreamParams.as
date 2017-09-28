// ===================================================================================================
//                           _  __     _ _
//                          | |/ /__ _| | |_ _  _ _ _ __ _
//                          | ' </ _` | |  _| || | '_/ _` |
//                          |_|\_\__,_|_|\__|\_,_|_| \__,_|
//
// This file is part of the Kaltura Collaborative Media Suite which allows users
// to do with audio, video, and animation what Wiki platfroms allow them to do with
// text.
//
// Copyright (C) 2006-2017  Kaltura Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// @ignore
// ===================================================================================================
package com.kaltura.vo
{
	import com.kaltura.vo.BaseFlexVo;

	[Bindable]
	public dynamic class KalturaLiveStreamParams extends BaseFlexVo
	{
		/**
		* Bit rate of the stream. (i.e. 900)
		**/
		public var bitrate : int = int.MIN_VALUE;

		/**
		* flavor asset id
		**/
		public var flavorId : String = null;

		/**
		* Stream's width
		**/
		public var width : int = int.MIN_VALUE;

		/**
		* Stream's height
		**/
		public var height : int = int.MIN_VALUE;

		/**
		* Live stream's codec
		**/
		public var codec : String = null;

		/**
		* Live stream's farme rate
		**/
		public var frameRate : int = int.MIN_VALUE;

		/**
		* Live stream's key frame interval
		**/
		public var keyFrameInterval : Number = Number.NEGATIVE_INFINITY;

		/**
		* Live stream's language
		**/
		public var language : String = null;

		/** 
		* a list of attributes which may be updated on this object 
		**/ 
		public function getUpdateableParamKeys():Array
		{
			var arr : Array;
			arr = new Array();
			arr.push('bitrate');
			arr.push('flavorId');
			arr.push('width');
			arr.push('height');
			arr.push('codec');
			arr.push('frameRate');
			arr.push('keyFrameInterval');
			arr.push('language');
			return arr;
		}

		/** 
		* a list of attributes which may only be inserted when initializing this object 
		**/ 
		public function getInsertableParamKeys():Array
		{
			var arr : Array;
			arr = new Array();
			return arr;
		}

		/** 
		* get the expected type of array elements 
		* @param arrayName 	 name of an attribute of type array of the current object 
		* @return 	 un-qualified class name 
		**/ 
		public function getElementType(arrayName:String):String
		{
			var result:String = '';
			switch (arrayName) {
			}
			return result;
		}
	}
}