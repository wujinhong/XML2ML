package core
{
	import flash.utils.ByteArray;

	/**
	 * XML配置编译器 
	 * @author masefee
	 * 2012-7-7
	 */	
	public class XMLCompiler
	{
		/** 面板类xml内置编译器 **/
		public static const PANEL_INNER_COMPILER:uint = 0;
		/** 配置类xml内置编译器 **/
		public static const CONFIG_INNER_COMPILER:uint = 1;
		/** 样式类xml内置编译器 **/
		public static const STYLE_INNER_COMPILER:uint = 2;
		/** 字体类xml内置编译器 **/
		public static const FONTSTYLE_INNER_COMPILER:uint = 3;
		/** 程序引用类xml内置编译器 **/
		public static const PROG_INC_INNER_COMPILER:uint = 4;
		/** 参数类xml内置编译器 **/
		public static const PARAM_INNER_COMPILER:uint = 5;
		/** 相等比较方法 **/
		public static const COMPARE_EQU:uint = 0;
		/** 包含比较方法 **/
		public static const COMPARE_HAVE:uint = 1;
		/** 注册的xml参数个数检测 **/
		private static const REG_XML_PARAM_CHK_CNT:uint = 3;
		/** 注册的xml编译器列表 **/
		private static var _regCompilers:Object = null;
		/** 注册要编译的xml配置列表 **/
		private static var _regXMLCfgs:Array = [];
		/** 注册要编译的xml配置列表 **/
		private static var _outSubPath:String;
		/** 注册要编译的xml配置列表 **/
		private static var _outFileExt:String;
		private var exit:Function;
		
		/**
		 * 构造函数
		 * @param console 编译信息输出对象，为null则使用trace输出
		 * <li>注意：需实现 function println( ...msg ):void; 接口
		 * @param cfgs 要编译的xml注册列表
		 * <li>格式：
		 * <br>[ 
		 * 		<br>&nbsp;&nbsp;&nbsp;&nbsp;[ CONFIG_INNER_COMPILER, COMPARE_EQU, "yourfile1.xml" ],
		 * 		<br>&nbsp;&nbsp;&nbsp;&nbsp;[ PANEL_INNER_COMPILER, COMPARE_HAVE, "yourfile2.xml" ],
		 * 		<br>&nbsp;&nbsp;&nbsp;&nbsp;...
		 * <br>]
		 * @param debug 是否是调试版本
		 * @param exit 退出回调
		 */		
		public function XMLCompiler( console:SecondThread, cfgs:Array, debug:Boolean, exit:Function )
		{
			_compilerConsole.console = console;
			_regXMLCfgs = cfgs;
			_compilerStatus.isDebug = debug;
			this.exit = exit;
			_regCompilers = {};
			_regCompilers[ PANEL_INNER_COMPILER ] = _panelXMLCompiler;
			_regCompilers[ CONFIG_INNER_COMPILER ] = _configXMLCompiler;
			_regCompilers[ STYLE_INNER_COMPILER ] = _styleXMLCompiler;
			_regCompilers[ FONTSTYLE_INNER_COMPILER ] = _fontStyleXMLCompiler;
			_regCompilers[ PROG_INC_INNER_COMPILER ] = _progIncXMLCompiler;
			_regCompilers[ PARAM_INNER_COMPILER ] = _paramXMLCompiler;
		}
		/**
		 * 编译xml文件 
		 * @param fileName xml文件
		 */		
		public function compile( fileName:String ):void
		{
			try
			{
				compiled( fileName );
			}
			catch ( err:Error )
			{
				_compilerConsole.println( "编译xml文件出错是：", "[" + fileName + "]", err.message, err.getStackTrace() );
				exit( -4 );
				return;
			}
		}
		
		/**
		 * 编译xml文件 
		 * @param fileName xml文件
		 */		
		public function compiled( fileName:String ):void
		{
			var compile_callback:Function = null;
			for ( var compIdx:int = 0; compIdx < _regXMLCfgs.length; ++compIdx )
			{
				var cfgArr:Array = _regXMLCfgs[ compIdx ];
				if ( cfgArr.length >= REG_XML_PARAM_CHK_CNT )
				{
					var match:Boolean = false;
					if ( cfgArr[ 1 ] == COMPARE_EQU )
						match = ( fileName == cfgArr[ 2 ] );
					else if ( cfgArr[ 1 ] == COMPARE_HAVE )
						match = ( fileName.indexOf( cfgArr[ 2 ] ) != -1 );
					else
						match = false;
					
					if ( match )
					{
						compile_callback = _regCompilers[ cfgArr[ 0 ] ].parseXML;
						break;
					}
				}
			}
			
			if ( compile_callback == null )
				return;
			
			var xml:XML = new XML( _compilerConsole.console.input );
			var xmlObj:Object = {};
			
			_compilerStatus.haveError = false;
			compile_callback( xml, xmlObj, true );
			
			if ( _compilerStatus.haveError )
			{
				exit( -3 );
				return;
			}
			_compilerConsole.console.output = new ByteArray();
			_compilerConsole.console.output.clear();
			_compilerConsole.console.output.writeObject( xmlObj );
			_compilerConsole.console.next();
			
			_ctrlRegisterCoder.buildRegisterCode();
		}
	}
}
import flash.utils.Dictionary;

import core.SecondThread;

/** 
 * 面板xml编译器
 * @author masefee
 * 2012-7-7
 */
internal class _panelXMLCompiler
{	
	/** 调试版排序索引 **/
	static private var _debugSortIdx:int = 0;
	
	/**
	 * 解析xml配置 
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 * @param args 编译参数(暂时搁置)
	 */		
	public static function parseXML( xml:XML, xmlObj:Object, args:* = null ):void
	{
		if ( args != null )
			_debugSortIdx = 0;
		
		parseXMLAttributes( xml, xmlObj );
		parseXMLChildren( xml, xmlObj );
	}
	
	/**
	 * 解析xml的属性
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 */
	public static function parseXMLAttributes( xml:XML, xmlObj:Object ):void
	{
		var attrs:XMLList = xml.attributes();
		for ( var idx:int = 0; idx < attrs.length(); ++idx )
		{
			var attr:XML = attrs[ idx ];
			var attrName:String = attr.localName();
			if ( attrName != _xmlKeywords.DESC && attrName != _xmlKeywords.PACK && attrName != _xmlKeywords.EXTERNAL )
			{
				var attrVal:String = String( attr );
				if ( attrName == _xmlKeywords.HTMLTEXT || attrName == _xmlKeywords.TIPS )
					attrVal = _htmlReplacer.replace_html( attrVal );
				
				xmlObj[ attrName ] = String( attrVal );
			}
			
			if ( attrName == _xmlKeywords.ITEMCLASS )
				_compilerConsole.error( xml, "invalid property name, 'itemClass' is a keywords" );
			if ( attrName == _xmlKeywords.CLASSNAME )
				_compilerConsole.error( xml, "invalid property name, 'className' is a keywords" );
		}
		
		_ctrlRegisterCoder.registCtrlName( xml, true );
	}
	
	/**
	 * 解析xml的子节点
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 */
	public static function parseXMLChildren( xml:XML, xmlObj:Object ):void
	{
		var children:XMLList = xml.children();
		if ( children.length() == 0 )
			return;
		
		var isContainer:Boolean = false;
		var xmlChildObj:Object = null;
		var haveID:Boolean = children[ 0 ].hasOwnProperty( _xmlKeywords.ID );
		var localName:String = children[ 0 ].localName();
		var noIDChildList:Array = [];
		for ( var idx:int = 0; idx < children.length(); ++idx )
		{
			var child:XML = children[ idx ];
			if ( haveID )
			{
				if ( child.hasOwnProperty( _xmlKeywords.ID ) )
				{
					if ( child.localName() == _ctrlKeywords.Param )
						_paramXMLCompiler.parseXML( child, xmlObj );	
					else
					{
						xmlChildObj = {};
						parseXML( child, xmlChildObj );
						
						if ( checkContainer( xml, child, xmlChildObj ) )
							xmlObj.itemClass = xmlChildObj;
						else
						{
							xmlObj[ child[ _xmlKeywords.ID ] ] = xmlChildObj;
							if ( _compilerStatus.isDebug )
							{
								xmlChildObj.debug_index = ++_debugSortIdx;
								xmlChildObj.debug_class_id = child.localName();
							}
						}
					}
				}
				else
				{
					_compilerConsole.error( child, "it must have an id, because it's brother have" );
				}
			}
			else if ( localName != null )
			{
				if ( child.hasOwnProperty( _xmlKeywords.ID ) )
				{
					_compilerConsole.error( child, "it can't have id, because it's brother haven't" );
				}
				else if ( child.localName() != null && child.localName() == localName )
				{
					xmlChildObj = {};
					parseXMLAttributes( child, xmlChildObj );
					if ( checkContainer( xml, child, xmlChildObj ) )
					{
						xmlObj.itemClass = xmlChildObj;
					}
					else
					{
						var noname_children:XMLList = child.children();
						var childnum:int = noname_children.length();
						if ( childnum > 1 )
						{
							_compilerConsole.error( child, "no id child can not have more than one child" );
						}
						else if ( childnum == 1 )
						{
							var nonamechild:XML = noname_children[ 0 ];
							if ( nonamechild.localName() != null )
							{
								_compilerConsole.error( nonamechild, "no id child can not have child that it's have localName" );
							}
							else
							{
								xmlChildObj.child = String( nonamechild );
							}
						}
						noIDChildList.push( xmlChildObj );	
					}
				}
				else
				{
					_compilerConsole.error( child, "child localName must be:", localName );
				}
			}
			else
			{
				if ( child.hasOwnProperty( _xmlKeywords.ID ) || child.localName() != null )
					_compilerConsole.error( child, "it can't have id or localName, because it's brother haven't" );
				else
					_compilerConsole.error( child, "no id and no localName" );
			}
		}
		
		if ( noIDChildList.length > 0 )
			xmlObj[ localName ] = noIDChildList;
	}
	
	/**
	 * 检测本节点是容器，如果是容器，则需要标记被包装的控件的类名
	 * @param xml 父节点配置
	 * @param child 子节点配置
	 * @param xmlObj 子节点对象
	 * @return 返回是否是容器控件
	 */	
	private static function checkContainer( xml:XML, child:XML, xmlObj:Object ):Boolean
	{
		var parentName:String = xml.localName();
		if ( parentName == _ctrlKeywords.GRID_CONTAINER || parentName == _ctrlKeywords.LIST || parentName == _ctrlKeywords.SLIDE_CONTAINER )
		{
			xmlObj.className = child.localName();	
			return true;
		}
		return false;
	}
}

/** 
 * 附加配置xml编译器
 * @author masefee
 * 2012-7-7
 */
internal class _configXMLCompiler
{	
	/**
	 * 解析xml配置 
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 * @param ignore_error 是否忽略本层错误
	 */		
	public static function parseXML( xml:XML, xmlObj:Object, ignore_error:Boolean = false ):void
	{
		parseXMLAttributes( xml, xmlObj );
		parseXMLChildren( xml, xmlObj, ignore_error );
	}
	
	/**
	 * 解析xml的属性
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 */
	public static function parseXMLAttributes( xml:XML, xmlObj:Object ):void
	{
		var attrs:XMLList = xml.attributes();
		for ( var idx:int = 0; idx < attrs.length(); ++idx )
		{
			var attr:XML = attrs[ idx ];
			var attrName:String = attr.localName();
			if ( attrName != _xmlKeywords.DESC && attrName != _xmlKeywords.PACK && attrName != _xmlKeywords.EXTERNAL )
			{
				var attrVal:String = String( attr );
				if ( attrName == _xmlKeywords.HTMLTEXT || attrName == _xmlKeywords.TIPS )
					attrVal = _htmlReplacer.replace_html( attrVal );
				
				xmlObj[ attrName ] = String( attrVal );
			}
		}
		
		_ctrlRegisterCoder.registCtrlName( xml, false );
	}
	
	/**
	 * 解析xml的子节点
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 * @param ignore_error 是否忽略本层错误
	 */
	public static function parseXMLChildren( xml:XML, xmlObj:Object, ignore_error:Boolean ):void
	{
		var children:XMLList = xml.children();
		if ( children.length() == 0 )
			return;
		
		var xmlChildObj:Object = null;
		var haveID:Boolean = children[ 0 ].hasOwnProperty( _xmlKeywords.ID );
		var localName:String = children[ 0 ].localName();
		var noIDChildList:Array = [];
		for ( var idx:int = 0; idx < children.length(); ++idx )
		{
			var child:XML = children[ idx ];
			if ( haveID || ignore_error )
			{
				if ( child.hasOwnProperty( _xmlKeywords.ID ) || ignore_error )
				{
					xmlChildObj = {};
					xmlObj[ ignore_error ? child.localName() : child[ _xmlKeywords.ID ] ] = xmlChildObj;
					parseXML( child, xmlChildObj );
				}
				else
				{
					_compilerConsole.error( child, "it must have an id, because it's brother have" );
				}
			}
			else if ( localName != null )
			{
				if ( child.hasOwnProperty( _xmlKeywords.ID ) )
				{
					_compilerConsole.error( child, "it can't have id, because it's brother haven't" );
				}
				else if ( child.localName() != null && child.localName() == localName )
				{
					xmlChildObj = {};
					parseXMLAttributes( child, xmlChildObj );
					
					var noname_children:XMLList = child.children();
					var childnum:int = noname_children.length();
					if ( childnum > 1 )
					{
						_compilerConsole.error( child, "no id child can not have more than one child" );
					}
					else if ( childnum == 1 )
					{
						var nonamechild:XML = noname_children[ 0 ];
						if ( nonamechild.localName() != null )
						{
							_compilerConsole.error( nonamechild, "no id child can not have child that it's have localName" );
						}
						else
						{
							xmlChildObj.child = String( nonamechild );
						}
					}
					
					noIDChildList.push( xmlChildObj );
				}
				else
				{
					_compilerConsole.error( child, "child localName must be:", localName );
				}
			}
			else
			{
				if ( child.hasOwnProperty( _xmlKeywords.ID ) || child.localName() != null )
					_compilerConsole.error( child, "it can't have id or localName, because it's brother haven't" );
				else
					_compilerConsole.error( child, "no id and no localName" );
			}
		}
		
		if ( noIDChildList.length > 0 )
			xmlObj[ localName ] = noIDChildList;
	}
}

/** 
 * 样式xml编译器
 * @author masefee
 * 2012-7-7
 */
internal class _styleXMLCompiler
{	
	/**
	 * 解析xml配置 
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 * @param root 是否为根节点
	 */		
	public static function parseXML( xml:XML, xmlObj:Object, root:Boolean = false ):void
	{
		parseXMLAttributes( xml, xmlObj );
		parseXMLChildren( xml, xmlObj, root );
	}
	
	/**
	 * 解析xml的属性
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 */
	public static function parseXMLAttributes( xml:XML, xmlObj:Object ):void
	{
		var attrs:XMLList = xml.attributes();
		for ( var idx:int = 0; idx < attrs.length(); ++idx )
		{
			var attr:XML = attrs[ idx ];
			var attrName:String = attr.localName();
			if ( attrName != _xmlKeywords.DESC && attrName != _xmlKeywords.PACK && attrName != _xmlKeywords.EXTERNAL )
			{
				var attrVal:String = String( attr );
				if ( attrName == _xmlKeywords.HTMLTEXT || attrName == _xmlKeywords.TIPS )
					attrVal = _htmlReplacer.replace_html( attrVal );
				
				xmlObj[ attrName ] = String( attrVal );
			}
		}
	}
	
	/**
	 * 解析xml的子节点
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 * @param root 是否为根节点
	 */
	public static function parseXMLChildren( xml:XML, xmlObj:Object, root:Boolean = false ):void
	{
		var children:XMLList = xml.children();
		if ( children.length() == 0 )
			return;
		
		var xmlChildObj:Object = null;
		var childmap:Dictionary = null;
		for ( var idx:int = 0; idx < children.length(); ++idx )
		{
			var child:XML = children[ idx ];
			if ( child.localName() != null )
			{
				if ( root )
				{
					xmlChildObj = {};
					xmlObj[ child.localName() ] = xmlChildObj;
					parseXML( child, xmlChildObj );
				}
				else
				{
					if ( childmap == null )
						childmap = new Dictionary();
						
					var localName:String = child.localName();
					var arrChild:Array = childmap[ localName ] as Array;
					if ( arrChild == null )
					{
						arrChild = new Array();
						childmap[ localName ] = arrChild;
					}
					
					xmlChildObj = {};
					parseXMLAttributes( child, xmlChildObj );
					
					var stylechildren:XMLList = child.children();
					var childnum:int = stylechildren.length();
					if ( childnum > 1 )
					{
						_compilerConsole.error( child, "no id child can not have more than one child" );
					}
					else if ( childnum == 1 )
					{
						var nonamechild:XML = stylechildren[ 0 ];
						if ( nonamechild.localName() != null )
						{
							_compilerConsole.error( nonamechild, "style child can not have child that it's have localName" );
						}
						else
						{
							xmlChildObj.child = String( nonamechild );
							arrChild.push( xmlChildObj );
						}
					}
				}
			}
			else
			{
				_compilerConsole.error( child, "no localName" );
			}
		}
		
		if ( childmap != null )
		{
			for ( var name:String in childmap )
			{
				var arrStyle:Array = childmap[ name ] as Array;
				xmlObj[ name ] = arrStyle;
			}
		}
	}
}

/** 
 * 字体样式xml编译器
 * @author masefee
 * 2012-7-7
 */
internal class _fontStyleXMLCompiler
{	
	/**
	 * 解析xml配置 
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 * @param root 是否为根节点
	 */		
	public static function parseXML( xml:XML, xmlObj:Object, root:Boolean = false ):void
	{
		parseXMLAttributes( xml, xmlObj );
		parseXMLChildren( xml, xmlObj, root );
	}
	
	/**
	 * 解析xml的属性
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 */
	public static function parseXMLAttributes( xml:XML, xmlObj:Object ):void
	{
		var attrs:XMLList = xml.attributes();
		for ( var idx:int = 0; idx < attrs.length(); ++idx )
		{
			var attr:XML = attrs[ idx ];
			var attrName:String = attr.localName();
			if ( attrName != _xmlKeywords.DESC && attrName != _xmlKeywords.PACK && attrName != _xmlKeywords.EXTERNAL )
			{
				var attrVal:String = String( attr );
				if ( attrName == _xmlKeywords.HTMLTEXT || attrName == _xmlKeywords.TIPS )
					attrVal = _htmlReplacer.replace_html( attrVal );
				
				xmlObj[ attrName ] = String( attrVal );
			}
		}
	}
	
	/**
	 * 解析xml的子节点
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 * @param root 是否为根节点
	 */
	public static function parseXMLChildren( xml:XML, xmlObj:Object, root:Boolean = false ):void
	{
		var children:XMLList = xml.children();
		if ( children.length() == 0 )
			return;
		
		var xmlChildObj:Object = null;
		var childmap:Dictionary = null;
		for ( var idx:int = 0; idx < children.length(); ++idx )
		{
			var child:XML = children[ idx ];
			if ( child.localName() != null )
			{
				if ( root )
				{
					if ( xmlObj.fonts == null )
						xmlObj.fonts = new Dictionary();
					
					xmlChildObj = {};
					parseXML( child, xmlChildObj );
					
					for ( var id:String in xmlChildObj.map )
						xmlObj.fonts[ id ] = xmlChildObj.map[ id ];
				}
				else
				{
					if ( childmap == null )
						childmap = new Dictionary();
					
					xmlChildObj = {};
					for ( var propName:Object in xmlObj )
					{
						var obj:Object = xmlObj[ propName ];
						xmlChildObj[ propName ] = obj;
					}
					
					if ( !child.hasOwnProperty( _xmlKeywords.ID ) )
						_compilerConsole.error( child, "font style no id" );
					
					parseXMLAttributes( child, xmlChildObj );
					childmap[ uint( xmlChildObj.id ) ] = xmlChildObj;
				}
			}
			else
			{
				_compilerConsole.error( child, "no localName" );
			}
		}
		
		if ( childmap != null )
			xmlObj.map = childmap;
	}
}

/** 
 * 程序引用的xml编译器
 * @author masefee
 * 2012-7-7
 */
internal class _progIncXMLCompiler
{	
	/**
	 * 解析xml配置 
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 * @param root 是否为根节点
	 */		
	public static function parseXML( xml:XML, xmlObj:Object, root:Boolean = false ):void
	{
		parseXMLAttributes( xml, xmlObj );
		parseXMLChildren( xml, xmlObj, root );
	}
	
	/**
	 * 解析xml的属性
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 */
	public static function parseXMLAttributes( xml:XML, xmlObj:Object ):void
	{
		var attrs:XMLList = xml.attributes();
		for ( var idx:int = 0; idx < attrs.length(); ++idx )
		{
			var attr:XML = attrs[ idx ];
			var attrName:String = attr.localName();
			if ( attrName != _xmlKeywords.DESC && attrName != _xmlKeywords.PACK && attrName != _xmlKeywords.EXTERNAL )
			{
				var attrVal:String = String( attr );
				if ( attrName == _xmlKeywords.HTMLTEXT || attrName == _xmlKeywords.TIPS )
					attrVal = _htmlReplacer.replace_html( attrVal );
				
				xmlObj[ attrName ] = String( attrVal );
			}
		}
	}
	
	/**
	 * 解析xml的子节点
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 * @param root 是否为根节点
	 */
	public static function parseXMLChildren( xml:XML, xmlObj:Object, root:Boolean = false ):void
	{
		var children:XMLList = xml.children();
		if ( children.length() == 0 )
			return;
		
		var xmlChildObj:Object = null;
		for ( var idx:int = 0; idx < children.length(); ++idx )
		{
			var child:XML = children[ idx ];
			if ( child.localName() != null )
			{
				if ( root )
				{
					if ( xmlObj.images == null )
						xmlObj.images = new Dictionary();
					
					if ( !child.hasOwnProperty( _xmlKeywords.ID ) )
						_compilerConsole.error( child, "image no id" );
					
					xmlObj.images[ uint( child.@id ) ] = String( child );
				}
			}
			else
			{
				_compilerConsole.error( child, "no localName" );
			}
		}
	}
}

/** 
 * 参数块xml编译器
 * @author masefee
 * 2012-7-31
 */
internal class _paramXMLCompiler
{
	/** 真条件 **/
	private static const TRUE:String = "true";
	/** 假条件 **/
	private static const FALSE:String = "false";
	/** 空字符串 **/
	private static const NULL:String = "";
	/** 空对象 **/
	private static const VALUE_NULL:String = "null";
	
	/** 数组类型左边界 **/
	private static const syntax_arr_left:String = "[";
	/** 数组类型右边界 **/
	private static const syntax_arr_right:String = "]";
	/** object类型左边界 **/
	private static const syntax_obj_left:String = "{";
	/** object类型右边界 **/
	private static const syntax_obj_right:String = "}";
	/** 语法分隔符 **/
	private static const syntax_spliter:String = ",";
	/** 字符串标记 **/
	private static const syntax_string_single:String = "'";
	/** 字符串连接符 **/
	private static const syntax_string_connecter:String = "+";
	/** 字符串标记 **/
	private static const syntax_string_double:String = "\"";
	/** key-value分隔符 **/
	private static const syntax_key_value_spliter:String = ":";
	
	/** array关键字 **/
	private static const kw_array:String = "array";
	/** object关键字 **/
	private static const kw_object:String = "object";
	/** string关键字 **/
	private static const kw_string:String = "string";
	/** var关键字 **/
	private static const kw_var:String = "var";
	
	/** bool类型 **/
	private static const t_bool:String = "bool";
	/** 有符号整型 **/
	private static const t_int:String = "int";
	/** 浮点类型 **/
	private static const t_number:String = "number";
	/** 无符号整型 **/
	private static const t_uint:String = "uint";
	
	/** 语法树 **/
	private static var _syntax_tree:*;
	/** 语法解析栈 **/
	private static var _syntax_stack:Array;
	/** 当前的语法标记 **/
	private static var _cur_syntax:String;
	/** 当前的解析后的语法串 **/
	private static var _cur_syntax_idx:int;
	/** 当前的语法键 **/
	private static var _cur_key:String;
	/** 当前的语法值 **/
	private static var _cur_value:*;
	/** 当前的语法组合值 **/
	private static var _merge_value:*;
	/** 当前语法值类型 **/
	private static var _value_type:String;
	/** 语法原始字符串 **/
	private static var _syntax_src_str:String;
	/** 语法原始字符串备份 **/
	private static var _syntax_src_str_bak:String;
	/** 是否需要增加语法索引 **/
	private static var _is_add_syntax_idx:Boolean;
	
	/**
	 * 解析xml配置 
	 * @param xml xml对象
	 * @param xmlObj xml编译后的对象
	 * @param root 是否是根节点
	 */		
	public static function parseXML( xml:XML, xmlObj:Object, root:Boolean = false ):void
	{
		if ( !root )
		{
			if ( xml.hasOwnProperty( _xmlKeywords.ID ) )
			{
				var params:Object = {};
				parseXMLChildren( xml, params );
				xmlObj[ xml.@id ] = params;
			}
			else
				_compilerConsole.error( xml, "xml param block must have an id" );
		}
		else
		{
			parseXMLChildren( xml, xmlObj );
		}
	}
	
	/**
	 * 解析xml的子节点
	 * @param xml xml对象
	 * @param params 参数列表对象
	 */
	public static function parseXMLChildren( xml:XML, params:Object ):void
	{
		var children:XMLList = xml.children();
		if ( children.length() == 0 )
			return;
		
		var xmlChildObj:Object = null;
		for ( var idx:int = 0; idx < children.length(); ++idx )
		{
			var child:XML = children[ idx ];
			if ( !check_param( child, params ) )
				continue;

			var param_key:String = String( child[ _xmlKeywords.ID ] );
			var param_name:String = String( child.localName() );
			var param_value:String = String( child.children()[0] );
			var param_type:String = String( child.@type );
			switch ( param_name )
			{
				case kw_array:
				{
					init_syntax_parser( params, param_key, param_value, kw_array, param_type );
					parse_array();
					break;
				}
				case kw_object:
				{
					init_syntax_parser( params, param_key, param_value, kw_object, param_type );
					parse_object();
					break;
				}
				case kw_string:
				{
					init_syntax_parser( params, param_key, param_value, null, param_type );
					params[ param_key ] = parse_string();
					break;
				}
				case kw_var:
				{
					params[ param_key ] = static_cast( check_param_type( child, kw_var ), param_value );
					break;
				}
			}
		}
	}
	
	/**
	 * 解析array类型的param 
	 * @param syntax_tree 语法树
	 */	
	private static function parse_array( syntax_tree:* = null ):void
	{
		if ( !chk_prev( syntax_arr_left ) )
			return;
		
		push_syntax( syntax_arr_left );
		cut( true );
		
		var node:* = buy_syntax_node( syntax_tree, kw_array, get_key() );
		while ( have_next() )
		{
			if ( !check_syntax( syntax_spliter ) )
				return;
			
			if ( !check_string( syntax_string_single ) )
				continue;
			
			if ( !check_string( syntax_string_double ) )
				continue;
			
			if ( char() == syntax_string_connecter )
				break;
				
			if ( char() == syntax_string_single )
			{
				if ( !add_or_skip_string( syntax_string_single ) )
					return;
			}
			else if ( char() == syntax_string_double )
			{
				if ( !add_or_skip_string( syntax_string_double ) )
					return;
			}
			else if ( char() == syntax_spliter )
			{
				if ( syntax() == syntax_spliter )
				{
					pop_syntax();
					cut();
				}
				else if ( syntax() == syntax_string_single )
				{
					
				}
				else if ( syntax() == syntax_string_double )
				{
					
				}
				else
				{
					cut_value()
					add_value();
				}
			}
			else if ( char() == syntax_arr_right )
			{
				if ( syntax() != syntax_arr_left )
				{
					out_error();
					return;
				}
				else
				{
					pop_syntax();
					cut_value();
					
					if ( !empty_value() )
						add_value();
					
					if ( stack_empty() )
					{
						if ( have_next() )
						{
							out_error();
							return;
						}
					}
					else
					{
						if ( char() != syntax_arr_right && char() != syntax_obj_right )
							push_syntax( syntax_spliter );
						break;
					}
				}
			}
			else if ( char() == syntax_arr_left )
			{
				parse_array( node );
			}
			else if ( char() == syntax_obj_left )
			{
				parse_object( node );
			}
			
			next();
		}
		
		if ( node == root() && !stack_empty() )
		{
			out_error();
			return;
		}
		
		function add_value( trim:Boolean = true ):void { if ( trim ){ _cur_value = trim_space( _cur_value ); } cast_value(); }
		function add_string_value():void {  node.push( _htmlReplacer.replace_html( _merge_value ) ); _merge_value = null; }
		function empty_value():Boolean { return ( _cur_value == null || _cur_value == NULL ); }
		function cast_value():void{ node.push( static_cast( _value_type, _htmlReplacer.replace_html( _cur_value ) ) ); }
		function add_or_skip_string( type:String ):Boolean
		{
			if ( syntax() == type )
			{
				pop_syntax();
				cut_value();
				merge_string();
				
				if ( char() != syntax_string_connecter )
				{
					add_string_value();
					if ( char() != syntax_arr_right )
						push_syntax( syntax_spliter );	
				}
				else
				{
					cut();
					if ( char() != syntax_string_single && char() != syntax_string_double )
					{
						out_error();
						return false;
					}
				}
			}
			else
			{
				if ( head() != char() )
				{
					out_error();
					return false;	
				}
				
				push_syntax( type );
				cut();
			}
			
			return true;
		}
	}

	/**
	 * 解析object类型的param
	 * @param syntax_tree 语法树
	 */	
	private static function parse_object( syntax_tree:* = null ):void
	{
		if ( !chk_prev( syntax_obj_left ) )
			return;
		
		push_syntax( syntax_obj_left );
		cut( true );
		
		var node:* = buy_syntax_node( syntax_tree, kw_object, get_key() );
		while ( have_next() )
		{
			if ( !check_syntax( syntax_spliter ) )
				return;
			
			if ( !check_string( syntax_string_single ) )
				continue;
			
			if ( !check_string( syntax_string_double ) )
				continue;
			
			if ( char() == syntax_string_connecter )
				break;
			
			if ( char() == syntax_key_value_spliter )
			{
				cut_key();
				if ( empty_key() )
				{
					out_error();
					return;
				}
				
				add_key();
				push_syntax( syntax_key_value_spliter );
			}
			else if ( char() == syntax_string_single )
			{
				if ( !add_or_skip_string( syntax_string_single ) )
					return;
			}
			else if ( char() == syntax_string_double )
			{
				if ( !add_or_skip_string( syntax_string_double ) )
					return;
			}
			else if ( char() == syntax_spliter )
			{
				if ( syntax() == syntax_spliter )
				{
					pop_syntax();
					cut();
				}
				else if ( syntax() == syntax_string_single )
				{
					
				}
				else if ( syntax() == syntax_string_double )
				{
					
				}
				else
				{
					cut_value();
					if ( empty_value() )
					{
						out_error();
						return;
					}
					
					add_value();
					pop_syntax();
				}
				
				if ( char() == syntax_obj_right )
				{
					out_error();
					return;
				}
			}
			else if ( char() == syntax_obj_right )
			{
				if ( syntax() == syntax_key_value_spliter )
				{
					pop_syntax();
					cut_value();
					if ( empty_value() )
					{
						out_error();
						return;
					}
					
					add_value();
				}
				else
				{
					cut();
				}
				
				if ( syntax() != syntax_obj_left )
				{
					out_error();
					return;
				}
				else
				{
					pop_syntax();

					if ( stack_empty() )
					{
						cut();
						if ( have_next() )
						{
							out_error();
							return;
						}
					}
					else
					{
						if ( char() != syntax_obj_right && char() != syntax_arr_right )
							push_syntax( syntax_spliter );
						break;
					}
				}
			}
			else if ( char() == syntax_obj_left )
			{
				if ( syntax() != syntax_key_value_spliter )
				{
					out_error();
					return;
				}
				
				pop_syntax();
				parse_object( node );
			}
			else if ( char() == syntax_arr_left )
			{
				if ( syntax() != syntax_key_value_spliter )
				{
					out_error();
					return;
				}
				
				pop_syntax();
				parse_array( node );
			}
			
			next();
		}
		
		if ( node == root() && !stack_empty() )
		{
			out_error();
			return;
		}
		
		function add_key():void { _cur_key = trim_space( _cur_key ); node[ _cur_key ] = null; }
		function add_value( trim:Boolean = true ):void { if ( trim ){ _cur_value = trim_space( _cur_value ); } cast_value(); }
		function add_string_value():void { node[ _cur_key ] = _htmlReplacer.replace_html( _merge_value ); _merge_value = null; }
		function empty_key():Boolean { return ( _cur_key == null || _cur_key == NULL ); }
		function empty_value():Boolean { return ( _cur_value == null || _cur_value == NULL ); }
		function cast_value():void{ node[ _cur_key ] = static_cast( _value_type, _htmlReplacer.replace_html( _cur_value ) ); }
		function add_or_skip_string( type:String ):Boolean
		{
			if ( syntax() == type )
			{
				pop_syntax();
				if ( syntax() != syntax_key_value_spliter )
				{
					cut_key();
					add_key();
					
					if ( char() != syntax_key_value_spliter )
					{
						out_error();
						return false;
					}
					
					push_syntax( syntax_key_value_spliter );
					cut();
				}
				else
				{
					cut_value();
					if ( empty_value() )
					{
						out_error();
						return false;
					}
					
					merge_string();
					
					if ( char() != syntax_string_connecter )
					{
						pop_syntax();
						add_string_value();
						if ( char() != syntax_obj_right )
							push_syntax( syntax_spliter );
					}
					else
					{
						cut();
						if ( char() != syntax_string_single && char() != syntax_string_double )
						{
							out_error();
							return false;
						}
					}
				}
			}
			else
			{
				if ( head() != char() )
				{
					out_error();
					return false;	
				}
				
				push_syntax( type );
				cut();
			}
			
			return true;
		}
	}
	
	/**
	 * 解析string类型的param
	 * @return 返回解析后的字符串
	 */	
	private static function parse_string():String
	{
		if ( head() != syntax_string_single && head() != syntax_string_double )
		{
			if ( !check_and_search_string( syntax_string_single ) )
				return null;
			
			if ( !check_and_search_string( syntax_string_double ) )
				return null;
			
			return _htmlReplacer.replace_html( _syntax_src_str );	
		}
		
		while ( have_next() )
		{
			if ( !check_string( syntax_string_single ) )
				continue;
			
			if ( !check_string( syntax_string_double ) )
				continue;
			
			if ( !add_or_skip_string( syntax_string_single ) )
				break;
			
			if ( !add_or_skip_string( syntax_string_double ) )
				break;
			
			if ( char() == syntax_string_connecter )
				break;
			
			next();
		}
		
		if ( !stack_empty() || have_next() )
		{
			out_error();
			return null;
		}
		
		function add_or_skip_string( type:String ):Boolean
		{
			if ( char() == type )
			{
				if ( syntax() == type )
				{
					pop_syntax();
					cut_value();
					merge_string();
					
					if ( char() != syntax_string_connecter )
						return false;
					else
					{
						cut();
						if ( !have_next() )
							out_error();
					}
				}
				else
				{
					push_syntax( type );
					cut();
				}
			}
			return true;
		}
		
		function check_and_search_string( type:String ):Boolean
		{
			var idx:int = _syntax_src_str.search( type );
			if ( idx != -1 )
			{
				_cur_syntax_idx = idx;
				cut();
				
				out_error();
				return false;
			}
			return true;
		}
		
		return _htmlReplacer.replace_html( _merge_value );
	}
	
	/**
	 * 去除两端的空格
	 * @param value 要去空格的字符串，默认为null，则去除当前语法字符串的空格
	 * @return 当value不为null是返回去除空格后的新字符串
	 */	
	private static function trim_space( value:String = null ):String
	{
		if ( value == null )
			_syntax_src_str = _syntax_src_str.replace( /(^\s*)|(\s*$)/g, "" );
		else
			value = value.replace( /(^\s*)|(\s*$)/g, "" );
		return value;
	}
	
	/**
	 * 静态强制类型转化
	 * @param type 转换类型
	 * @param value 转化值
	 * @return 转化后的对象
	 */
	private static function static_cast( type:String, value:String ):*
	{
		var cast_ret:* = null;
		switch ( type )
		{
			case t_bool: cast_ret = ( value == TRUE ); break;
			case t_int: cast_ret = int( value ); break;
			case t_number: cast_ret = Number( value ); break;
			case t_uint: cast_ret = uint( value ); break;
			default: cast_ret = value; break;
		}
		
		if ( value == VALUE_NULL )
			cast_ret = null;
		return cast_ret;
	}
	
	/**
	 * 取得语法树根节点
	 * @return 根节点
	 */
	private static function root():*
	{
		return _syntax_tree;
	}
	
	/**
	 * 取得头部字符
	 * @return 返回头部字符
	 */
	private static function head():String
	{
		return _syntax_src_str.charAt( 0 );
	}
	
	/**
	 * 取得一个字符
	 * @return 当前索引处的字符
	 */
	private static function char():String
	{
		return _syntax_src_str.charAt( _cur_syntax_idx );
	}
	
	/**
	 * 索引向后移动
	 */
	private static function next():void
	{
		if ( _is_add_syntax_idx )
			++_cur_syntax_idx;
		_is_add_syntax_idx = true;
	}
	
	/**
	 * 是否到了结尾
	 * @return 是否结尾
	 */
	private static function have_next():Boolean
	{
		return ( _cur_syntax_idx < _syntax_src_str.length );
	}
	
	/**
	 * 检测字符串类型语法
	 * @return 是否为字符串
	 */
	private static function check_string( type:String ):Boolean
	{ 
		if ( syntax() == type )
		{
			if ( char() != type )
			{ 
				next(); 
				return false; 
			} 
		} 
		return true; 
	}
	
	/**
	 * 检测语法标记是否合法
	 * @return 是否合法
	 */
	private static function check_syntax( type:String ):Boolean
	{ 
		if ( syntax() == type )
		{
			if ( char() != type )
			{ 
				out_error();
				return false; 
			} 
		} 
		return true; 
	}
	
	/**
	 * 获取key值 
	 * @return key值
	 */	
	private static function get_key():String
	{
		return _cur_key;
	}
	
	/**
	 * 清除key值 
	 */	
	private static function clear_key():void
	{
		_cur_key = null;
	}
	
	/**
	 * 丢弃指定索引前面的字符
	 * @param idx 字符索引
	 */
	private static function drop( idx:int ):void
	{
		_syntax_src_str = _syntax_src_str.substr( idx );
	}
	
	/**
	 * 剪切从开头到当前索引的字符串
	 * @param next 是否允许下次索引增加
	 */
	private static function cut( next:Boolean = false ):void
	{
		_syntax_src_str = _syntax_src_str.substr( _cur_syntax_idx );
		_is_add_syntax_idx = next;
		_cur_syntax_idx = 0;
		skip_trim();
	}
	
	/**
	 * 剪切从开头到当前索引的字符串键值
	 * @param next 是否允许下次索引增加
	 */
	private static function cut_key( next:Boolean = false ):void
	{
		_cur_key = _syntax_src_str.substr( 0, _cur_syntax_idx );
		_syntax_src_str = _syntax_src_str.substr( _cur_syntax_idx );
		_is_add_syntax_idx = next;
		_cur_syntax_idx = 0;
		skip_trim();
	}
	
	/**
	 * 剪切从开头到当前索引的字符串值
	 * @param next 是否允许下次索引增加
	 */
	private static function cut_value( next:Boolean = false ):void
	{
		_cur_value = _syntax_src_str.substr( 0, _cur_syntax_idx );
		_syntax_src_str = _syntax_src_str.substr( _cur_syntax_idx );
		_is_add_syntax_idx = next;
		_cur_syntax_idx = 0;
		skip_trim();
	}
	
	/**
	 * 跳跃一个字符并返回新的去掉前后空格的字符串
	 */	
	private static function skip_trim():void
	{
		_syntax_src_str = _syntax_src_str.substr( 1 );
		if ( syntax() != syntax_string_single && syntax() != syntax_string_double )
			trim_space();
	}
	
	/**
	 * 检测前边界语法合法性 
	 * @param type 语法标记类型
	 * @return 是否合法
	 */	
	private static function chk_prev( type:String ):Boolean
	{
		trim_space();
		if ( head() != type )
		{
			out_error();
			return false;
		}
		return true;
	}
	
	/**
	 * 合并多个段的字符串，主要用于换行
	 */	
	private static function merge_string():void
	{
		if ( _merge_value == null )
			_merge_value = _cur_value;
		else
			_merge_value += _cur_value;
	}
	
	/**
	 * 输出错误 
	 */	
	private static function out_error():void
	{
		_compilerConsole.error( _syntax_src_str_bak, 
			"xml param syntax error, near by characters: '", 
			_syntax_src_str.substr( 0, 5 ), "', by index:", _syntax_src_str_bak.lastIndexOf( _syntax_src_str ),
			" in ", _syntax_src_str_bak.length, " characters",
			", please check it"
		);
	}
	
	/**
	 * 初始化语法解析容器 
	 * @param syntax_str 语法原始字符串
	 * @param param 面板参数对象
	 * @param param_key 参数key
	 * @param param_value 参数value
	 * @param type 参数类型
	 * @param value_type 参数值类型
	 */	
	private static function init_syntax_parser( param:Object, param_key:String, param_value:String, type:String, value_type:String ):void
	{
		_cur_syntax = null;
		_cur_value = null;
		_merge_value = null;
		_syntax_stack = [];
		_cur_syntax_idx = 0;
		_value_type = value_type;
		_syntax_src_str = param_value;
		_syntax_src_str_bak = param_value;
		
		var node:* = null;
		if ( type == kw_array )
			_syntax_tree = [];
		else if ( type == kw_object )
			_syntax_tree = {};
		else
			_syntax_tree = null;
		
		if ( _syntax_tree != null )
			param[ param_key ] = _syntax_tree; 
	}
	
	/**
	 * 构建一个语法树节点
	 * @param syntax_tree 要添加到的树节点
	 * @param type 添加的类型
	 * @param key 添加Object时作为key使用
	 * @return 返回添加的node
	 */	
	private static function buy_syntax_node( syntax_tree:*, type:String, key:String = null ):*
	{
		var node:* = _syntax_tree;
		if ( syntax_tree != null )
		{
			switch ( type )
			{
				case kw_array: node = []; break;
				case kw_object: node = {}; break;
			}
			
			if ( syntax_tree is Array )
				syntax_tree.push( node );
			else
				syntax_tree[ key ] = node;
		}
		
		return node;
	}
	
	/**
	 * 压入一个语法标记到栈
	 * @param type 要压入的类型
	 */	
	private static function push_syntax( type:String ):void
	{
		_cur_syntax = type;
		_syntax_stack.push( type );
	}
	
	/**
	 * 弹出一个语法标记
	 * @return 弹出的语法标记
	 */	
	private static function pop_syntax():String
	{
		var syntax:String = _syntax_stack.pop();
		if ( _syntax_stack.length > 0  )
			_cur_syntax = _syntax_stack[ _syntax_stack.length - 1 ];
		else
			_cur_syntax = null;
		return syntax;
	}
	
	/**
	 * 获取当前栈顶的语法标记
	 * @return 语法标记
	 */	
	private static function syntax():String
	{
		return _cur_syntax;
	}
	
	/**
	 * 获得语法栈是否为空
	 * @return 是否为空
	 */	
	private static function stack_empty():Boolean
	{
		return ( _syntax_stack.length == 0 );
	}
	
	/**
	 * 检测param节点的合法性 
	 * @param xml 节点xml
	 * @param params 参数列表
	 * @return 是否合法
	 */	
	private static function check_param( xml:XML, params:Object ):Boolean
	{
		var param_name:String = xml.localName();
		if ( param_name == null )
		{
			_compilerConsole.error( xml, "xml param must have a name" );
			return false;
		}
		
		if ( !xml.hasOwnProperty( _xmlKeywords.ID ) )
		{
			_compilerConsole.error( xml, "xml param must have an id" );
			return false;
		}
		
		var param_key:String = String( xml[ _xmlKeywords.ID ] );
		if ( params[ param_key ] != null )
		{
			_compilerConsole.error( xml, "xml param id duplicate definition" );
			return false;
		}
		
		var values:XMLList = xml.children();
		if ( values.length() == 0 || values.length() > 1 )
		{
			_compilerConsole.error( xml, "xml param must have a value and only one value" );
			return false;
		}
		
		var value_xml:XML = values[ 0 ];
		if ( value_xml.localName() != null )
		{
			_compilerConsole.error( xml, "xml param value can not have local name" );
			return false;
		}
		
		return true;
	}
	
	/**
	 * 检测param节点类型
	 * @param xml 节点xml
	 * @param keywords 参数的关键字
	 * @return 检测成功则返回类型名，否则返回null
	 */	
	private static function check_param_type( xml:XML, keywords:String ):String
	{
		if ( !xml.hasOwnProperty( _xmlKeywords.TYPE ) )
		{
			_compilerConsole.error( xml, "xml param '" + keywords + "' must have param type" );
			return null;
		}
		return String( xml[ _xmlKeywords.TYPE ] );
	}
}

/**
 * html语法替换器
 * @author masefee
 * 2012-7-7
 */
internal class _htmlReplacer
{
	/** 对齐参数列表 **/
	private static const ALIGN_LIST:Array = [ "left", "center", "right" ];
	
	/** 对齐参数列表 **/
	private static var _cur_rep_syntax_str:String = null;
	
	/**
	 * 对于字符串类型的value进行html语法编译 
	 * @param syntax_str 语法字符串
	 * @return 编译后的html文本
	 */	
	public static function replace_html( syntax_str:String ):String
	{
		var reg_exp:RegExp = null;
		var reg_obj:Object = null;
		var match_str:String = null;
		var result_syntax_str:String = null;
		
		_cur_rep_syntax_str = syntax_str;
		
		syntax_str = syntax_str.replace( /\{u\}/ig, "<u>" );
		syntax_str = syntax_str.replace( /\{\/u\}/ig, "</u>" );
		syntax_str = syntax_str.replace( /\{b\}/ig, "<b>" );
		syntax_str = syntax_str.replace( /\{\/b\}/ig, "</b>" );
		syntax_str = syntax_str.replace( /\{\/f\}/ig, "</font>" );
		syntax_str = syntax_str.replace( /\{br\}/ig, "<br>" );
		syntax_str = syntax_str.replace( /\{\/a\}/ig, "</a>" );
		syntax_str = syntax_str.replace( /\{p\}/ig, "<p>" );
		syntax_str = syntax_str.replace( /\{\/p\}/ig, "</p>" );
		
		result_syntax_str = "";
		reg_exp = new RegExp( /\{f=[a-f0-9]{9}\}/i );
		reg_obj = reg_exp.exec( syntax_str );
		while ( reg_obj != null )
		{
			result_syntax_str += syntax_str.substr( 0, reg_obj.index );
			match_str = String( reg_obj[ 0 ] );
			
			var size_face:uint = uint( "0x" + match_str.substr( 9, match_str.length - 10 ) );//{f=FFFFFF0a0}取出0a0
			var color:String = match_str.substr( 3, 6 );//{f=FFFFFF0a0}取出FFFFFF
			var size:String = String( ( size_face & 0x00000ff0 ) >> 4 );// 2 的4次方等于12，{f=FFFFFF0a0}取出0a
			var faceIdx:int = ( size_face & 0x0000000f );//{f=FFFFFF0a0}取出最后的0
			if ( faceIdx < 0 || faceIdx >= SecondThread.FONT_LIST.length )
			{
				out_error();
				return null;
			}
			
			result_syntax_str += "<font face='" + SecondThread.FONT_LIST[ faceIdx ] + "' color='#" + color + "' size='" + size + "'>";
			
			syntax_str = syntax_str.substr( reg_obj.index + match_str.length );
			reg_obj = reg_exp.exec( syntax_str );
		}
		
		result_syntax_str += syntax_str;
		syntax_str = result_syntax_str;
		
		result_syntax_str = "";
		reg_exp = new RegExp( /\{a=.*?\}/i );
		reg_obj = reg_exp.exec( syntax_str );
		while ( reg_obj != null )
		{
			result_syntax_str += syntax_str.substr( 0, reg_obj.index );
			match_str = String( reg_obj[ 0 ] );
			
			var event:String = match_str.substr( 3, match_str.length - 4 );
			result_syntax_str += "<a href='event:" + event + "'>";
			
			syntax_str = syntax_str.substr( reg_obj.index + match_str.length );
			reg_obj = reg_exp.exec( syntax_str );
		}
		
		result_syntax_str += syntax_str;
		syntax_str = result_syntax_str;
		
		result_syntax_str = "";
		reg_exp = new RegExp( /\{p=\d\}/i );
		reg_obj = reg_exp.exec( syntax_str );
		while ( reg_obj != null )
		{
			result_syntax_str += syntax_str.substr( 0, reg_obj.index );
			match_str = String( reg_obj[ 0 ] );
			
			var alignIdx:int = int( match_str.substr( 3, match_str.length - 4 ) );
			if ( alignIdx < 0 || alignIdx >= ALIGN_LIST.length )
			{
				out_error();
				return null;
			}
			
			result_syntax_str += "<p align='" + ALIGN_LIST[ alignIdx ] + "'>";

			syntax_str = syntax_str.substr( reg_obj.index + match_str.length );
			reg_obj = reg_exp.exec( syntax_str );
		}
		
		result_syntax_str += syntax_str;
		
		return result_syntax_str;
	}
	
	/**
	 * 输出错误 
	 */	
	private static function out_error():void
	{
		_compilerConsole.error( _cur_rep_syntax_str, "xml html syntax error, please check it:" );
	}
}


/** 
 * xml编译器的命令行
 * @author masefee
 * 2012-7-7
 */
internal class _compilerConsole
{
	/** xml节点ID关键字 **/
	private static const _printKey:String = "println";
	/** xml节点ID关键字 **/
	public static var console:SecondThread;
	
	/**
	 * 命令行输出 
	 */
	public static function println( ...msg ):void
	{
		if ( console != null && console.hasOwnProperty( _printKey ) )
			console.println( msg );
		else
			trace.apply( null, msg );
	}
	
	/**
	 * 命令行错误输出
	 */
	public static function error( node:*, ...msg ):void
	{
		var msgstring:String = msg.join( " " );
		println( "error:", msgstring, ", xml:", node.toString() );
		_compilerStatus.haveError = true;
	}
}

/**
 * xml关键字
 * @author masefee
 * 2012-7-7
 */
internal class _xmlKeywords
{
	/** xml节点ID关键字 **/
	public static const ID:String = "@id";
	/** xml节点type关键字 **/
	public static const TYPE:String = "@type";
	/** xml节点注释关键字 **/
	public static const DESC:String = "desc";
	/** xml节点是否打包关键字 **/
	public static const PACK:String = "pack";
	/** xml节点html属性关键字 **/
	public static const HTMLTEXT:String = "htmltext";
	/** xml节点tips属性关键字 **/
	public static const TIPS:String = "tips";
	/** xml节点外部类关键字 **/
	public static const EXTERNAL:String = "external";
	/** xml节点类对象关键字 **/
	public static const ITEMCLASS:String = "itemClass";
	/** xml节点类名关键字 **/
	public static const CLASSNAME:String = "className";
	/** xml节点基础控件前缀关键字 **/
	public static const UI:String = "UI";
	/** xml节点自定义控件后缀关键字 **/
	public static const ITEM:String = "Item";
}

/**
 * 一些关键的控件关键字 
 * @author masefee
 * 2012-7-9
 */
internal class _ctrlKeywords
{
	/** 格子容器 **/
	public static const GRID_CONTAINER:String = "UIGridContainer";
	/** 列表控件 **/
	public static const LIST:String = "UIList";
	/** 幻灯片控件 **/
	public static const SLIDE_CONTAINER:String = "UISlideContainer";
	/** 参数块 **/
	public static const Param:String = "UIParam";
}

/**
 * 控件注册代码生成器
 * @author masefee
 * 2012-7-9
 */
internal class _ctrlRegisterCoder
{
	/** 基础控件池 **/
	private static var _baseCtrlPool:Dictionary = new Dictionary();
	/** 自定义控件池 **/
	private static var _userCtrlPool:Dictionary = new Dictionary();
	/** 注册代码文件名 **/
	private static var _asOutFileName:String = "UICtrlRegister.as";
	/** 注册代码模板 **/
	private static var _reg_code_template:String = "        ctrl_pool[ \"{name}\" ] = {name};\n";
	/** 代码模板 **/
	private static var _code_template:String =
	"package view.core.base\n" +
	"{\n" +
	"    import flash.utils.Dictionary;\n\n" +
	"    import view.core.ctrl.*;\n" +
	"    import view.userctrl.*;\n\n" +
	"    /**\n" +
	"     * 控件类注册（只会注册跟配置相关的控件），此类由xml编译器生成，不推荐手工编写\n" + 
	"     * @author masefee\n" +
	"     * 2012-7-9\n" +
	"     */\n" +
	"    public class UICtrlRegister\n" +
	"    {\n" +
	"        /** ui组件类对象池 **/\n" +
	"        public static var ctrl_pool:Dictionary = new Dictionary();\n\n" +
	"        /** 注册组件 **/\n{code}" +
	"    }\n" +
	"}";
	
	
	/**
	 * 检测本节点并注册到控件池中
	 * @param xml 节点配置
	 * @param base 是否是基础控件
	 */	
	public static function registCtrlName( xml:XML, base:Boolean ):void
	{
		var ctrlName:String = xml.localName();
		var isBaseCtrl:Boolean = ctrlName.indexOf( _xmlKeywords.UI ) == 0;
		if ( base )
		{
			if ( isBaseCtrl )
				_baseCtrlPool[ ctrlName ] = ctrlName;
		}
		else
		{
			if ( !isBaseCtrl && ctrlName.indexOf( _xmlKeywords.ITEM ) == ( ctrlName.length - _xmlKeywords.ITEM.length ) )
				_userCtrlPool[ ctrlName ] = ctrlName;
		}
	}
	
	/**
	 * 生成控件注册的代码
	 */
	public static function buildRegisterCode():void
	{
		var regcode:String = "";
		var ctrlName:String = "";
		for each ( ctrlName in _baseCtrlPool )
			regcode += _reg_code_template.replace( /\{name\}/g, ctrlName );
		
		for each ( ctrlName in _userCtrlPool )
			regcode += _reg_code_template.replace( /\{name\}/g, ctrlName );
		
		var ascode:String = _code_template.replace( /\{code\}/g, regcode );
		
		_compilerConsole.console.saveAS( _asOutFileName, ascode );
	}
}

/**
 * xml编译器的状态
 * @author masefee
 * 2012-7-7
 */
internal class _compilerStatus
{
	/** 是否存在编译错误 **/
	public static var haveError:Boolean;
	/** 是否是调试版本 **/
	public static var isDebug:Boolean;
}