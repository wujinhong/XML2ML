/*******************************************************************************************************************************************
 * This is an automatically generated class. Please do not modify it since your changes may be lost in the following circumstances:
 *     - Members will be added to this class whenever an embedded worker is added.
 *     - Members in this class will be renamed when a worker is renamed or moved to a different package.
 *     - Members in this class will be removed when a worker is deleted.
 *******************************************************************************************************************************************/

package 
{
	
	import flash.utils.ByteArray;
	
	public class Workers
	{
		
		[Embed(source="../workerswfs/core/SecondThread.swf", mimeType="application/octet-stream")]
		private static var core_SecondThread_ByteClass:Class;
		public static function get core_SecondThread():ByteArray
		{
			return new core_SecondThread_ByteClass();
		}
		
	}
}
