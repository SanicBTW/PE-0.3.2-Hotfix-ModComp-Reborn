package;

//just like loading state but this one runs on startup

import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
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

class PreloadState extends MusicBeatState
{
    inline static var MIN_TIME = 1.0;

    var target:FlxState;
    var callbacks:MultiCallback;
    var targetShit:Float = 0;

    function new(target:FlxState)
    {
        super();
        this.target = target;
    }

    var loadBar:FlxSprite;

    override function create()
    {
        loadBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 10, FlxColor.GREEN);
        loadBar.screenCenter();
        loadBar.antialiasing = ClientPrefs.globalAntialiasing;
        add(loadBar);

        initModManifest().onComplete(function(lib)
        {
            callbacks = new MultiCallback(onLoad);
            var introComplete = callbacks.add("introComplete");
            checkLibrary(ClientPrefs.modDirectory);

            var fadeTime = 0.5;
			FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
			new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
        });

        super.create();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(callbacks != null) 
        {
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadBar.scale.x += 0.5 * (targetShit - loadBar.scale.x);
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

    inline static public function loadAndSwitchState(target:FlxState)
    {
        MusicBeatState.switchState(getNextState(target));
    }

    function onLoad()
	{
		MusicBeatState.switchState(target);
	}

    static function getNextState(target:FlxState):FlxState
    {
        Paths.setCurrentLevel(ClientPrefs.modDirectory);

        var loaded:Bool = false;

        loaded = isLibraryLoaded(ClientPrefs.modDirectory);

        return new PreloadState(target);
    }

    static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}

    override function destroy()
	{
		super.destroy();

		callbacks = null;
	}

    static function initModManifest()
	{
		var id = ClientPrefs.modDirectory;
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