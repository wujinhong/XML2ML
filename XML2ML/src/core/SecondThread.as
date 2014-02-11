package core
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.utils.ByteArray;
	
	public class SecondThread extends Sprite
	{
		/** 内置xml编译器 **/
		private var _xmlcompiler:XMLCompiler = null;
		/** 是否为调试版本 **/
		private static const DEBUG:String = "debug";
		/** 是否为发布版本 **/
		private static const RELEASE:String = "release";
		/** 支持的字体列表 **/
		public static var FONT_LIST:Array = [ "SimSun", "Microsoft YaHei", "LiSu" ];
		/** 注册的所有xml **/
		private static const REG_XMLS:Array =
			[
				[ XMLCompiler.PANEL_INNER_COMPILER, XMLCompiler.COMPARE_HAVE, "Panel.xml" ],
				[ XMLCompiler.CONFIG_INNER_COMPILER, XMLCompiler.COMPARE_EQU, "UITypes.xml" ],
				[ XMLCompiler.STYLE_INNER_COMPILER, XMLCompiler.COMPARE_EQU, "Style.xml" ],
				[ XMLCompiler.FONTSTYLE_INNER_COMPILER, XMLCompiler.COMPARE_EQU, "FontStyles.xml" ],
				[ XMLCompiler.CONFIG_INNER_COMPILER, XMLCompiler.COMPARE_EQU, "Collect.xml" ],
				[ XMLCompiler.PROG_INC_INNER_COMPILER, XMLCompiler.COMPARE_EQU, "ProgrameInclude.xml" ],
				[ XMLCompiler.PARAM_INNER_COMPILER, XMLCompiler.COMPARE_EQU, "NonCfgParams.xml" ],
				[ XMLCompiler.PARAM_INNER_COMPILER, XMLCompiler.COMPARE_EQU, "LogicParams.xml" ],
				[ XMLCompiler.PARAM_INNER_COMPILER, XMLCompiler.COMPARE_EQU, "TextStyles.xml" ],
				[ XMLCompiler.PARAM_INNER_COMPILER, XMLCompiler.COMPARE_EQU, "MockConfig.xml" ],
				[ XMLCompiler.PARAM_INNER_COMPILER, XMLCompiler.COMPARE_EQU, "RegisterParams.xml" ],
			];
		
		private var debug:String;
		private var mainToWorker:MessageChannel;
		private var workerToMain:MessageChannel;
		private var worker:Worker;
		public var input:ByteArray;
		public var output:ByteArray;
		public function SecondThread()
		{
			super();
			_xmlcompiler = new XMLCompiler( this, REG_XMLS, debug == DEBUG, exitFunc );
			
			worker =Worker.current;
			mainToWorker = worker.getSharedProperty( "mainToWorker" );
			workerToMain = worker.getSharedProperty( "workerToMain" );
			debug = worker.getSharedProperty( "debug" );
			mainToWorker.addEventListener( Event.CHANNEL_MESSAGE, onMainToWorker );
		}
		private function onMainToWorker(event:Event):void
		{
			var receive:String = mainToWorker.receive();
			if ( receive.split( "." )[ 1 ] == "xml" )
			{
				FONT_LIST = worker.getSharedProperty( "font" );
				input = worker.getSharedProperty( "input" );
				_xmlcompiler.compile( receive );
			}
			else
			{
				exitFunc( -4 );
			}
		}
		public function saveAS( fileName:String, code:String ):void
		{
			worker.setSharedProperty( "code", code );
			workerToMain.send( "as" );
			workerToMain.send( fileName );
		}
		public function next():void
		{
			output.shareable = true;
			worker.setSharedProperty( "output", output );
			workerToMain.send( "next" );
		}
		public function println( ...msg ):void
		{
			workerToMain.send( "println" );
			workerToMain.send( msg );
		}
		private function exitFunc( code:int = 0 ):void
		{
			workerToMain.send( "exit" );
			workerToMain.send( code );
		}
	}
}