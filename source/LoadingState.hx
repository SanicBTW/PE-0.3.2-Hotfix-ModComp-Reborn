package;

import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import flixel.util.FlxTimer;
import haxe.io.Path;
import lime.app.Future;
import lime.app.Promise;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets;

using StringTools;

// update to the loading state, originally from scarlet melopeia port
class LoadingState extends MusicBeatState
{
	inline static var MIN_TIME = 1.0;

	// Browsers will load create(), you can make your song load a custom directory there
	// If you're compiling to desktop (or something that doesn't use NO_PRELOAD_ALL), search for getNextState instead
	// I'd recommend doing it on both actually lol
	// TO DO: Make this easier
	var target:FlxState;
	var stopMusic = false;
	var directory:String;
	var callbacks:MultiCallback;
	var targetShit:Float = 0;

	function new(target:FlxState, stopMusic:Bool, directory:String)
	{
		super();
		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}

	var bg:FlxSprite;
	var loadBar:FlxBar;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var bgColorTween:FlxTween;
	var lastColor:FlxColor;

	override function create()
	{
		Conductor.changeBPM(102);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		lastColor = bg.color;

		gfDance = new FlxSprite(552, 0);
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		add(gfDance);

		loadBar = new FlxBar();
		loadBar.screenCenter();
		loadBar.y = FlxG.height * 0.97;
		loadBar.screenCenter(X);
		loadBar.scale.set(12, 1);
		loadBar.antialiasing = ClientPrefs.globalAntialiasing;
		add(loadBar);

		initSongsManifest().onComplete(function(lib)
		{
			callbacks = new MultiCallback(onLoad);
			var introComplete = callbacks.add("introComplete");
			if (PlayState.SONG != null)
			{
				checkLoadSong(getSongPath());
				if (PlayState.SONG.needsVoices)
					checkLoadSong(getVocalPath());
			}
			for(i in 0...Main.loadLibs.length)
				checkLibrary(Main.loadLibs[i]);
			if (directory != null && directory.length > 0 && directory != 'shared')
			{
				checkLibrary(directory);
				Main.clearLibs.push(directory);
			}

			var fadeTime = 0.5;
			FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
			new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
		});
	}

	function checkLoadSong(path:String)
	{
		if (!Assets.cache.hasSound(path))
		{
			var callback = callbacks.add("song:" + path);
			Assets.loadSound(path).onComplete(function(_)
			{
				callback();
			});
		}
	}

	function checkLibrary(library:String)
	{
		if (Assets.getLibrary(library) == null)
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw "Missing library: " + library;

			var callback = callbacks.add("library:" + library);
			Assets.loadLibrary(library).onComplete(function(_)
			{
				callback();
			});
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		Conductor.songPosition = FlxG.sound.music.time;

		if (callbacks != null)
		{
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadBar.percent = 100 * targetShit;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (gfDance != null)
		{
			danceLeft = !danceLeft;

			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		if (curBeat % 4 == 0)
		{
			var curNewColor:FlxColor = FlxG.random.color();
			if(bgColorTween != null)
				bgColorTween.cancel();
			bgColorTween = FlxTween.color(bg, 1, lastColor, curNewColor, { onComplete: function(twn:FlxTween)
			{
				lastColor = curNewColor;
				bgColorTween = null;
			}});
		}
	}

	function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		MusicBeatState.switchState(target);
	}

	static function getSongPath()
	{
		return Paths.inst(PlayState.SONG.song);
	}

	static function getVocalPath()
	{
		return Paths.voices(PlayState.SONG.song);
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false)
	{
		MusicBeatState.switchState(getNextState(target, stopMusic));
	}

	static function getNextState(target:FlxState, stopMusic = false):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '')
			directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);

		#if NO_PRELOAD_ALL
		var loaded:Bool = false;

		if (PlayState.SONG != null)
		{
			loaded = isSoundLoaded(getSongPath())
				&& (!PlayState.SONG.needsVoices || isSoundLoaded(getVocalPath()))
				&& isLibraryLoaded(directory)
				&& areLibrariesLoaded();
		}

		if (!loaded)
			return new LoadingState(target, stopMusic, directory);
		#end
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		return target;
	}

	#if NO_PRELOAD_ALL
	static function isSoundLoaded(path:String):Bool
	{
		return Assets.cache.hasSound(path);
	}

	static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}

	//i dont belive this is working butttt alright
	static function areLibrariesLoaded():Bool
	{
		for(i in 0...Main.loadLibs.length)
		{
			trace(Main.loadLibs[i]);
			trace(Assets.getLibrary(Main.loadLibs[i]) != null);
			return Assets.getLibrary(Main.loadLibs[i]) != null;
		}
		return false;
	}
	#end

	override function destroy()
	{
		super.destroy();

		callbacks = null;
		bgColorTween = null;
	}

	static function initSongsManifest()
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
				promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}