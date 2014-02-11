package common
{
	import flash.display.DisplayObject;
	import flash.system.Capabilities;
	
	import spark.components.WindowedApplication;

	/**
	 * @author Gordon
	 * 使flex窗口居中
	 */
	public function windowMiddle( w:WindowedApplication ):void
	{
		w.nativeWindow.x = ( Capabilities.screenResolutionX - w.nativeWindow.width ) >> 1;
		w.nativeWindow.y = ( Capabilities.screenResolutionY - w.nativeWindow.height )>> 1;
	}
	/**
	 * 使ui在父窗口居中; (注意：w必须先添加到场景中)
	 * @author Gordon
	 */
	public function uiMiddle( w:DisplayObject ):void
	{
		w.x = ( w.parent.width - w.width ) >> 1;
		w.y = ( w.parent.height - w.height )>> 1;
	}
}