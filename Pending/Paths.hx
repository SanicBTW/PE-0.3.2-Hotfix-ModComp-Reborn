package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class Paths
{
	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetManager.AssetType = DIRECTORY, ?group:String, ?library:String)
	{
		return AssetManager.getAsset(file, type, group, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return AssetManager.getAsset(key, TEXT, 'data', library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return AssetManager.getAsset(key, XML, 'data', library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return AssetManager.getAsset(key, JSON, 'data', library);
	}

	static public function sound(key:String, ?library:String)
	{
		return AssetManager.getAsset(key, SOUND, 'sounds', library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return AssetManager.getAsset(key, SOUND, 'music', library);
	}

	inline static public function voices(song:String)
	{
		return AssetManager.getAsset("Voices", SOUND, 'songs/${formatToSongPath(song)}/', "songs");
	}

	inline static public function inst(song:String)
	{
		return AssetManager.getAsset("Inst", SOUND, 'songs/${formatToSongPath(song)}/', "songs");
	}

	inline static public function image(key:String, ?library:String):Dynamic
	{
		return AssetManager.getAsset(key, IMAGE, 'images', library);
	}

	inline static public function font(key:String, ?library:String)
	{
		return AssetManager.getAsset(key, FONT, 'fonts', library);
	}

	inline static public function fileExists(key:String, type:AssetManager.AssetType, ?group:String, ?library:String)
	{
		if (OpenFlAssets.exists(AssetManager.getPath(key, group, type, library)))
		{
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}

	inline static public function formatToSongPath(path:String)
	{
		return path.toLowerCase().replace(' ', '-');
	}
}
