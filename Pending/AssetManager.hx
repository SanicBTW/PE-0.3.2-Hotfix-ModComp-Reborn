package;

import openfl.Assets;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

//kind of based off from forever engine asset manager ig
enum abstract AssetType(String) to String
{
    var IMAGE = 'image';
	var SPARROW = 'sparrow';
	var SOUND = 'sound';
	var FONT = 'font';
	var DIRECTORY = 'directory';
	var JSON = 'json';
    var PACKER = "packer";
    var TEXT = "text";
    var XML = "xml";
}

class AssetManager
{
    public static function getAsset(directory:String, type:AssetType = DIRECTORY, group:Null<String> = null, library:Null<String> = null):Dynamic
    {
        var gottenPath = getPath(directory, group, type, library);
        switch(type)
        {
            case JSON | TEXT | XML:
                return Assets.getText(gottenPath);
            case SPARROW:
                var imagePath = getPath(directory, group, IMAGE, library);
                trace('sparrow image path $imagePath');
                trace('sparrow xml path $gottenPath');
                return FlxAtlasFrames.fromSparrow(imagePath, Assets.getText(gottenPath));
            case PACKER:
                var imagePath = getPath(directory, group, IMAGE, library);
                trace('packer image path $imagePath');
                trace('packer txt path $gottenPath');
                return FlxAtlasFrames.fromSpriteSheetPacker(imagePath, Assets.getText(gottenPath));
            default:
                trace('returning directory $gottenPath');
                return gottenPath;
        }
        trace('returning null for $gottenPath');
        return null;
    }

    public static function getPath(directory:String, group:Null<String> = null, type:AssetType = DIRECTORY, library:Null<String> = null):String
    {
        var pathBase:String = "";

        if (library != null || library != "preload" || library != "default" || library != "")
            pathBase = '$library:assets/$library/';
        else
            pathBase = "assets/";

        var directoryExtension = '$group/$directory';
        return filterExtensions('$pathBase$directoryExtension', type);
    }

    public static function filterExtensions(directory:String, type:String)
    {
        if(!Assets.exists(directory))
        {
            var extensions:Array<String> = [];
            switch(type)
            {
                case IMAGE:
                    extensions = ['.png'];
                case JSON:
                    extensions = ['.json'];
                case PACKER | TEXT:
                    extensions = [".txt"];
                case SPARROW | XML:
                    extensions = ['.xml'];
                case SOUND:
                    extensions = ['.ogg'];
                case FONT:
                    extensions = ['.ttf', '.otf'];
            }
            trace(extensions);

            for(i in extensions)
            {
                var returnDirectory:String = '$directory$i';
                trace('attempting directory $returnDirectory');
                if(Assets.exists(returnDirectory))
                {
                    trace('successful extension $i');
                    return returnDirectory;
                }
            }
        }
        trace('no extension needed, returning $directory');
        return directory;
    }
}