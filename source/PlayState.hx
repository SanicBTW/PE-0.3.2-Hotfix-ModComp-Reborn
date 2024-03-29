package;

import DialogueBoxPsych;
import Section.SwagSection;
import Song.SwagSong;
import StageData.StageFile;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.media.Video;
import openfl.system.System;
import openfl.utils.Assets as OpenFlAssets;
import Note.EventNote;

using StringTools;

#if desktop
import Discord.DiscordClient;
#end

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;
	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;
	private var lastSection:Int = 0;
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;

	private var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	private var camZooming:Bool = true;
	private var curSong:String = "";
	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;
	private var healthBarBG:AttachedSprite;

	public var healthBar:FlxBar;

	var songPercent:Float = 0;
	private var timeBarBG:AttachedSprite;
	private var timeBar:FlxBar;
	private var generatedMusic:Bool = false;
	private var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = false;

	public static var practiceMode:Bool = false;
	public static var usedPractice:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var cpuControlled:Bool = false;

	var botplaySine:Float = 0;
	var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	public static var daPixelZoom:Float = 6;

	var singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

	public var inCutscene:Bool = false;

	var songLength:Float = 0;

	public static var displaySongName:String = "";

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;
	public var introSoundsSuffix:String = '';

	public static var inst:Dynamic = null;
	public static var voices:Dynamic = null;
	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastScore:Array<FlxSprite> = [];

	var curFont = null; // to properly set the font on format

	var camDisplaceX:Float = 0;
	var camDisplaceY:Float = 0;

	var mashViolations:Int = 0;

	override public function create()
	{
		PauseSubState.songName = null; // Reset to default
		Conductor.recalculateTimings();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (inst == null)
			inst = Paths.inst(PlayState.SONG.song);
		if (PlayState.SONG.needsVoices && voices == null)
			voices = Paths.voices(PlayState.SONG.song);

		practiceMode = false;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		var songName:String = SONG.song;
		displaySongName = StringTools.replace(songName, '-', ' ');

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = PlayState.SONG.stage;
		if (PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1)
		{
			switch (songName)
			{
				default:
					curStage = 'stage';
			}
		}
		PlayState.SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		if (curFont == null)
			curFont = (isPixelStage ? Paths.font("pixel.otf") : Paths.font("vcr.ttf"));

		switch (curStage)
		{
			case 'stage': // Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if (!ClientPrefs.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
		}

		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup);

		add(dadGroup);
		add(boyfriendGroup);

		/*
		switch (curStage)
		{
		}*/

		var file:String = Paths.json(songName + '/dialogue'); // Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				default:
					gfVersion = 'gf';
			}

			SONG.player3 = gfVersion; // Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll)
			strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 20, 400, "", 32);
		timeTxt.setFormat(curFont, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = !ClientPrefs.hideTime;
		if (ClientPrefs.downScroll)
			timeTxt.y = FlxG.height - 45;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = !ClientPrefs.hideTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = !ClientPrefs.hideTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if (ClientPrefs.downScroll)
			healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.visible = !ClientPrefs.hideHud;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.visible = !ClientPrefs.hideHud;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(curFont, 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(curFont, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if (ClientPrefs.downScroll)
		{
			botplayTxt.y = timeBarBG.y - 78;
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];

		#if android
		addAndroidControls();
		androidControls.visible = false;
		addPadCamera();
		#end

		startingSong = true;
		updateTime = true;

		var daSong:String = curSong.toLowerCase();
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		// precache if vol higher than 0
		if (ClientPrefs.missVolume > 0)
		{
			CoolUtil.precacheSound('missnote1');
			CoolUtil.precacheSound('missnote2');
			CoolUtil.precacheSound('missnote3');
		}

		if (ClientPrefs.hitsoundVolume > 0)
			CoolUtil.precacheSound('hitsound');

		if (PauseSubState.songName != null)
			CoolUtil.precacheMusic(PauseSubState.songName);
		else if (ClientPrefs.pauseMusic != null)
			CoolUtil.precacheMusic(Paths.formatToSongPath(ClientPrefs.pauseMusic));

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		super.create();

		openfl.system.System.gc();

		CustomFadeTransition.nextCamera = camOther;
	}

	public function reloadHealthBarColors()
	{
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					newBoyfriend.alreadyLoaded = false;
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					newDad.alreadyLoaded = false;
				}

			case 2:
				if (!gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					newGf.alreadyLoaded = false;
				}
		}
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			Main.tweenFPS(false, 0.5);
			Main.tweenMemory(false, 0.5);
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong)
			{
				endSong();
			}
			else
			{
				startCountdown();
			}
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;
	var perfectMode:Bool = false;

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			return;
		}
		
		#if android
		androidControls.visible = true;
		#end

		Main.tweenFPS(true, 0.5);
		Main.tweenMemory(true, 0.5);

		inCutscene = false;
		generateStaticArrows(0);
		generateStaticArrows(1);
		for (i in 0...playerStrums.length)
		{
		}
		for (i in 0...opponentStrums.length)
		{
			if (ClientPrefs.middleScroll)
				opponentStrums.members[i].visible = false;
		}

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			if (gf != null
				&& tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
				&& !gf.stunned
				&& gf.animation.curAnim.name != null
				&& !gf.animation.curAnim.name.startsWith("sing")
				&& !gf.stunned)
			{
				gf.dance();
			}
			if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0
				&& boyfriend.animation.curAnim != null
				&& !boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.stunned)
			{
				boyfriend.dance();
			}
			if (tmr.loopsLeft % dad.danceEveryNumBeats == 0
				&& dad.animation.curAnim != null
				&& !dad.animation.curAnim.name.startsWith('sing')
				&& !dad.stunned)
			{
				dad.dance();
			}

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', 'set', 'go']);
			introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var antialias:Bool = ClientPrefs.globalAntialiasing;
			if (isPixelStage)
			{
				introAlts = introAssets.get('pixel');
				antialias = false;
			}

			/*
			switch (curStage)
			{
			}*/

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.cameras = [camHUD];
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (isPixelStage)
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					ready.antialiasing = antialias;
					insert(members.indexOf(notes), ready);
					FlxTween.tween(ready, {y: ready.y + 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.cameras = [camHUD];
					set.scrollFactor.set();
					set.updateHitbox();

					if (isPixelStage)
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					set.antialiasing = antialias;
					insert(members.indexOf(notes), set);
					FlxTween.tween(set, {y: set.y + 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.cameras = [camHUD];
					go.scrollFactor.set();
					go.updateHitbox();

					if (isPixelStage)
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.screenCenter();
					go.antialiasing = antialias;
					insert(members.indexOf(notes), go);
					FlxTween.tween(go, {y: go.y + 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
				case 4:
					canPause = true;
			}

			if (generatedMusic)
			{
				notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
			}

			swagCounter += 1;
		}, 5);
	}

	function startNextDialogue()
	{
		dialogueCount++;
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		System.gc();

		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(inst, 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBarBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
	}

	private function generateSong(dataPath:String):Void
	{
		System.gc();

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(voices);
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(inst));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		if (OpenFlAssets.exists(file))
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if (songNotes[1] > -1) //REAL NOTES FFS I HATE MY LIFE SO MUCH
				{
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % 4);
	
					var gottaHitNote:Bool = section.mustHitSection;
	
					if (songNotes[1] > 3)
					{
						gottaHitNote = !section.mustHitSection;
					}
	
					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;
	
					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.mustPress = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
					swagNote.noteType = songNotes[3];
					if (!Std.isOfType(songNotes[3], String))
						swagNote.noteType = ChartingState.noteTypeList[songNotes[3]];
	
					swagNote.scrollFactor.set();
	
					var susLength:Float = swagNote.sustainLength;
	
					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);
	
					var floorSus:Int = Math.floor(susLength);
	
					if (floorSus > 0)
					{
						for (susNote in 0...floorSus + 2)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
	
							var sustainNote:Note = new Note(daStrumTime
								+ (Conductor.stepCrochet * susNote)
								+ (Conductor.stepCrochet / FlxMath.roundDecimal(SONG.speed, 2)), daNoteData,
								oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							
							unspawnNotes.push(sustainNote);
	
							if (sustainNote.mustPress)
								sustainNote.x += FlxG.width / 2;
	
							if (ClientPrefs.osuManiaSimulation && susLength < susNote)
								sustainNote.isLiftNote = true;
						}
					}
	
					swagNote.mustPress = gottaHitNote;
	
					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
				}
				else //THE FUCKING STUPID EVENT NOTES GOD
				{
					//wtf??? do i push songNotes or this shit 
					for(i in 0...songNotes[1].length)
					{
						var newEventNote:Array<Dynamic> = [songNotes[0], songNotes[1][i][0], songNotes[1][i][1], songNotes[1][i][2]];
						var subEvent:EventNote = 
						{
							strumTime: newEventNote[0] + ClientPrefs.noteOffset,
							event: newEventNote[1],
							value1: newEventNote[2],
							value2: newEventNote[3]
						};
						subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
						eventNotes.push(subEvent);
						eventPushed(subEvent);
					}
					/*
					eventNotes.push(songNotes);
					eventPushed(songNotes);*/
				}
			}
			daBeats += 1;
		}

		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1)
		{ // No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) 
	{
		switch(event.event) 
		{
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) 
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float 
	{
		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false;

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;

			if (!isStoryMode && !skipArrowStartTween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = 1;
			}

			switch (player)
			{
				case 0:
					opponentStrums.add(babyArrow);
				case 1:
					playerStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = false;
				}
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = true;
				}
			}
			paused = false;

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, displaySongName
					+ " ("
					+ storyDifficultyText
					+ ")", iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, displaySongName
					+ " ("
					+ storyDifficultyText
					+ ")", iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end
		
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		if (!paused && startedCountdown && canPause && !inCutscene && ClientPrefs.pauseOnFocusLost)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = false;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if (!inCutscene)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		super.update(elapsed);

		scoreTxt.text = getScoreTextFormat();

		if (cpuControlled)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}
		botplayTxt.visible = cpuControlled;

		if (controls.PAUSE #if android || FlxG.android.justReleased.BACK #end && startedCountdown && canPause && !inCutscene)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			#if desktop
			DiscordClient.changePresence(detailsPausedText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			#end
		}

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			+ (150 * iconP1.scale.x - 150) / 2
			- iconOffset;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			- (150 * iconP2.scale.x) / 2
			- iconOffset * 2;

		if (health >= 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}

				if (updateTime)
				{
					var curTime:Float = FlxG.sound.music.time - ClientPrefs.noteOffset;
					if (curTime < 0)
						curTime = 0;
					songPercent = (curTime / songLength);

					var secondsTotal:Int = Math.floor((songLength - curTime) / 1000);
					if (secondsTotal < 0)
						secondsTotal = 0;

					var minutesRemaining:Int = Math.floor(secondsTotal / 60);
					var secondsRemaining:String = '' + secondsTotal % 60;
					if (secondsRemaining.length < 2)
						secondsRemaining = '0' + secondsRemaining; // Dunno how to make it display a zero first in Haxe lol
					timeTxt.text = minutesRemaining + ':' + secondsRemaining;
				}
			}
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			var curSection = Std.int(curStep / 16);
			if (curSection != lastSection)
			{
				if (PlayState.SONG.notes[lastSection] != null)
				{
					var lastMustHit:Bool = PlayState.SONG.notes[lastSection].mustHitSection;
					if (SONG.notes[curSection].mustHitSection != lastMustHit)
					{
						camDisplaceX = 0;
						camDisplaceY = 0;
					}
					lastSection = Std.int(curStep / 16);
				}
			}

			updateCamFollow(elapsed);
		}

		if (camZooming)
		{
			if (ClientPrefs.smoothCamZoom)
			{
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
				camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			}
			else
			{
				// this from kade - idk if there is a notable difference tbh
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
				camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
			}
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		FlxG.watch.addQuick("curBPM", Conductor.bpm);

		// RESET = Quick Game Over Screen
		if (controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}

		doDeathCheck();

		var roundedSpeed:Float = FlxMath.roundDecimal(SONG.speed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if (roundedSpeed < 1)
				time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				if (!daNote.mustPress && ClientPrefs.middleScroll)
				{
					daNote.active = true;
					daNote.visible = false;
				}
				else if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				// i am so fucking sorry for this if condition
				var strumY:Float = 0;
				if (daNote.mustPress)
				{
					strumY = playerStrums.members[daNote.noteData].y;
				}
				else
				{
					strumY = opponentStrums.members[daNote.noteData].y;
				}
				var center:Float = strumY + Note.swagWidth / 2;

				if (ClientPrefs.downScroll)
				{
					daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
					if (daNote.isSustainNote)
					{
						// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
						if (daNote.animation.curAnim.name.endsWith('end'))
						{
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
							if (curStage == 'school' || curStage == 'schoolEvil')
							{
								daNote.y += 8;
							}
						}
						daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1);

						if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
							&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
				}
				else
				{
					daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

					if (daNote.isSustainNote
						&& daNote.y + daNote.offset.y * daNote.scale.y <= center
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
						swagRect.y = (center - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;

						daNote.clipRect = swagRect;
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if (daNote.mustPress && cpuControlled)
				{
					if (daNote.isSustainNote)
					{
						if (daNote.canBeHit)
						{
							goodNoteHit(daNote);
						}
					}
					else if (daNote.strumTime <= Conductor.songPosition)
					{
						goodNoteHit(daNote);
					}
				}

				var doKill:Bool = daNote.y < -daNote.height;
				if (ClientPrefs.downScroll)
					doKill = daNote.y > FlxG.height;

				if (doKill)
				{
					if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
					{
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();

		if (!inCutscene)
		{
			if (!cpuControlled)
			{
				keyShit();
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
			}
			cameraDisplacement(boyfriend, true);
			cameraDisplacement(dad, false);
		}

		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
				FlxG.sound.music.onComplete();
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.strumTime + 800 < Conductor.songPosition)
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length)
				{
					var daNote:Note = unspawnNotes[0];
					if (daNote.strumTime + 800 >= Conductor.songPosition)
					{
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}
		#end
	}

	public var isDead:Bool = false;

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if ((skipHealthCheck || health <= 0) && !practiceMode && !isDead)
		{
			boyfriend.stunned = true;
			deathCounter++;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			camHUD.alpha = 0;
			camOther.alpha = 0;
			boyfriendGroup.alpha = 0;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.x, boyfriend.y));

			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			#end
			isDead = true;
			return true;
		}
		return false;
	}

	public function checkEventNote()
	{
		while(eventNotes.length > 0) 
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) 
			{
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, ?onLua:Bool = false)
	{
		switch (eventName)
		{
			case 'Hey!':
				var value:Int = Std.parseInt(value1);
				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter == 'gf')
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
					else
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				trace('Anim to play: ' + value1);
				var val2:Int = Std.parseInt(value2);
				if (Math.isNaN(val2))
					val2 = 0;

				var char:Character = dad;
				switch (val2)
				{
					case 1: char = boyfriend;
					case 2: char = gf;
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2))
					val2 = 0;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var val:Int = Std.parseInt(value1);
				if (Math.isNaN(val))
					val = 0;

				var char:Character = dad;
				switch (val)
				{
					case 1: char = boyfriend;
					case 2: char = gf;
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = Std.parseFloat(split[0].trim());
					var intensity:Float = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = Std.parseInt(value1);
				if (Math.isNaN(charType))
					charType = 0;

				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							if (!boyfriend.alreadyLoaded)
							{
								boyfriend.alpha = 1;
								boyfriend.alreadyLoaded = true;
							}
							boyfriend.visible = true;
							iconP1.changeIcon(boyfriend.healthIcon);
						}

					case 1:
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							dad.visible = false;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf'))
							{
								if (wasGf)
								{
									gf.visible = true;
								}
							}
							else
							{
								gf.visible = false;
							}
							if (!dad.alreadyLoaded)
							{
								dad.alpha = 1;
								dad.alreadyLoaded = true;
							}
							dad.visible = true;
							iconP2.changeIcon(dad.healthIcon);
						}

					case 2:
						if (gf.curCharacter != value2)
						{
							if (!gfMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var isGfVisible:Bool = gf.visible;
							gf.visible = false;
							gf = gfMap.get(value2);
							if (!gf.alreadyLoaded)
							{
								gf.alpha = 1;
								gf.alreadyLoaded = true;
							}
							gf.visible = isGfVisible;
						}
				}
		}
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if (ClientPrefs.noteOffset <= 0)
		{
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
			{
				finishCallback();
			});
		}
	}

	function endSong():Void
	{
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;
		KillNotes();

		if (SONG.validScore && !cpuControlled && !changedDifficulty && !usedPractice)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if (Math.isNaN(percent))
				percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			#end
		}

		if (isStoryMode)
		{
			campaignScore += songScore;
			campaignMisses += songMisses;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				if (FlxTransitionableState.skipNextTransIn)
				{
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new StoryMenuState());

				if (usedPractice == false && changedDifficulty == false && cpuControlled == false)
				{
					StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

					if (SONG.validScore)
					{
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
					}

					FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
					FlxG.save.flush();
				}
				usedPractice = false;
				changedDifficulty = false;
				cpuControlled = false;
			}
			else
			{
				// btw DID I JUST FUCKING FIX THE FINISH SONG ISSUE, BRO I CANT BELIVE IT WAS THIS EASY FUCK
				// i swear to god, i need to learn how to name variables :skull:
				var difficulty:String = CoolUtil.getDifficultyFilePath();
				var nextSong = PlayState.storyPlaylist[0].toLowerCase().replace(" ", "-");

				trace('LOADING NEXT SONG');
				trace(nextSong + difficulty);

				prevCamFollow = camFollow;
				prevCamFollowPos = camFollowPos;

				PlayState.SONG = Song.loadFromJson(nextSong + difficulty, nextSong);
				// make these null to avoid any errors in the future
				PlayState.inst = null;
				PlayState.voices = null;
				System.gc();
				FlxG.sound.music.stop();

				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			if (FlxTransitionableState.skipNextTransIn)
			{
				CustomFadeTransition.nextCamera = null;
			}
			MusicBeatState.switchState(new FreeplayState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			usedPractice = false;
			changedDifficulty = false;
			cpuControlled = false;
		}
	}

	private function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		vocals.volume = 1;

		var coolText:FlxText = new FlxText(0, 0, 0, "", 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		coolText.cameras = [camHUD];

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating = Conductor.judgeNote(note, noteDiff);

		// this shit comin from the 0.5.2h kade input thing
		switch (daRating)
		{
			case 'shit':
				totalNotesHit += 0.25;
				note.ratingMod = 0.25;
				score = -300;
				combo = 0;
				songMisses++;
				health -= 0.2;
				if (!note.ratingDisabled)
					shits++;
			case 'bad':
				totalNotesHit += 0.5;
				note.ratingMod = 0.5;
				score = 0;
				health -= 0.06;
				if (!note.ratingDisabled)
					bads++;
			case 'good':
				totalNotesHit += 0.75;
				note.ratingMod = 0.75;
				score = 200;
				if (!note.ratingDisabled)
					goods++;
			case 'sick':
				totalNotesHit += 1;
				note.ratingMod = 1;
				if (!note.ratingDisabled)
					sicks++;
		}
		note.rating = daRating;

		if (daRating == "sick" && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		songScore += score;
		if (!note.ratingDisabled)
		{
			songHits++;
			totalPlayed++;
			RecalculateRating();
		}

		if (ClientPrefs.optScoreZoom)
		{
			if (!cpuControlled)
			{
				if (scoreTxtTween != null)
				{
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween)
					{
						scoreTxtTween = null;
					}
				});
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (isPixelStage)
		{
			pixelShitPart1 = "pixelUI/";
			pixelShitPart2 = "-pixel";
		}

		rating.loadGraphic(Paths.getLibraryPath(ClientPrefs.ratingsStyle + "/" + daRating + pixelShitPart2 + ".png", "UILib"));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		rating.visible = (!ClientPrefs.hideHud);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		insert(members.indexOf(strumLineNotes), rating);
		if (!ClientPrefs.comboStacking)
		{
			if (lastRating != null)
				lastRating.kill();
			lastRating = rating;
		}

		if (!isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
		}

		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		rating.cameras = [camHUD];

		var daLoop:Int = 0;
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!ClientPrefs.comboStacking)
				lastScore.push(numScore);

			if (!isPixelStage)
			{
				if(ClientPrefs.smallRatingSize)
				{
					rating.setGraphicSize(Std.int(rating.width * 0.7));
					rating.antialiasing = ClientPrefs.globalAntialiasing;
				}
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}

			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			numScore.visible = !ClientPrefs.hideHud;

			insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.001
			});

			daLoop++;
		}

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function keyShit():Void
	{
		if (ClientPrefs.inputType == "Kade 1.5.3")
		{
			var holdArray:Array<Bool> = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_P,
				controls.NOTE_DOWN_P,
				controls.NOTE_UP_P,
				controls.NOTE_RIGHT_P
			];
			var releaseArray:Array<Bool> = [
				controls.NOTE_LEFT_R,
				controls.NOTE_DOWN_R,
				controls.NOTE_UP_R,
				controls.NOTE_RIGHT_R
			];

			if (!boyfriend.stunned && generatedMusic)
			{
				if (controlArray.contains(true))
				{
					boyfriend.holdTimer = 0;

					var possibleNotes:Array<Note> = [];
					var directionList:Array<Int> = [];
					var dumbNotes:Array<Note> = [];
	
					notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isLiftNote)
						{
							if (directionList.contains(daNote.noteData))
							{
								for (coolNote in possibleNotes)
								{
									if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
									{
										dumbNotes.push(daNote);
										break;
									}
									else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
									{
										possibleNotes.remove(coolNote);
										possibleNotes.push(daNote);
										break;
									}
								}
							}
							else
							{
								possibleNotes.push(daNote);
								directionList.push(daNote.noteData);
							}
						}
					});
	
					for (note in dumbNotes)
					{
						FlxG.log.add("killing dumb ass note at " + note.strumTime);
						note.kill();
						notes.remove(note, true);
						note.destroy();
					}
	
					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
	
					var dontCheck = false;
	
					for (i in 0...controlArray.length)
					{
						if (controlArray[i] && !directionList.contains(i))
							dontCheck = true;
					}
	
					if (possibleNotes.length > 0 && !dontCheck)
					{
						if (!ClientPrefs.ghostTapping)
						{
							for (shit in 0...controlArray.length)
							{
								if (controlArray[shit] && !directionList.contains(shit))
									noteMissPress(shit);
							}
						}

						for (coolNote in possibleNotes)
						{
							if (controlArray[coolNote.noteData] && coolNote.canBeHit && !coolNote.tooLate)
							{
								if (mashViolations != 0)
									mashViolations--;
								scoreTxt.color = FlxColor.WHITE;
								goodNoteHit(coolNote);
							}
						}
					}
					else if (!ClientPrefs.ghostTapping)
					{
						for (shit in 0...controlArray.length)
						{
							if (controlArray[shit] && !directionList.contains(shit))
								noteMissPress(shit);
						}
					}
	
					if (dontCheck && possibleNotes.length > 0)
					{
						if (mashViolations > 4)
						{
							FlxG.log.add("mash violations " + mashViolations);
							scoreTxt.color = FlxColor.RED;
							for (shit in 0...controlArray.length)
							{
								noteMissPress(shit);
							}
						}
						else
							mashViolations++;
					}
				}

				if (releaseArray.contains(true) && ClientPrefs.osuManiaSimulation)
				{
					boyfriend.holdTimer = 0;

					var possibleNotes:Array<Note> = [];
					var directionList:Array<Int> = [];
					var dumbNotes:Array<Note> = [];

					notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && daNote.isLiftNote)
						{
							if (directionList.contains(daNote.noteData))
							{
								for (coolNote in possibleNotes)
								{
									if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
									{
										dumbNotes.push(daNote);
										break;
									}
									else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
									{
										possibleNotes.remove(coolNote);
										possibleNotes.push(daNote);
										break;
									}
								}
							}
							else
							{
								possibleNotes.push(daNote);
								directionList.push(daNote.noteData);
							}
						}
					});
	
					for (note in dumbNotes)
					{
						FlxG.log.add("killing dumb ass note at (release arr) " + note.strumTime);
						note.kill();
						notes.remove(note, true);
						note.destroy();
					}

					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					var dontCheck = false;

					for (i in 0...releaseArray.length)
					{
						if (releaseArray[i] && !directionList.contains(i))
							dontCheck = true;
					}

					if (possibleNotes.length > 0 && !dontCheck)
					{
						for (coolNote in possibleNotes)
						{
							if (releaseArray[coolNote.noteData])
							{
								if (mashViolations != 0)
									mashViolations--;
								scoreTxt.color = FlxColor.WHITE;
								goodNoteHit(coolNote, true);
							}
						}
					}

					if (dontCheck && possibleNotes.length > 0)
					{
						if (mashViolations > 4)
						{
							FlxG.log.add("mash violations " + mashViolations);
							scoreTxt.color = FlxColor.RED;
							for (shit in 0...releaseArray.length)
							{
								noteMissPress(shit);
							}
						}
						else
							mashViolations++;
					}
				}

				if (holdArray.contains(true))
				{
					notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote && holdArray[daNote.noteData] && !daNote.isLiftNote)
							goodNoteHit(daNote);
					});
				}
			}

			notes.forEachAlive(function(daNote:Note)
			{
				if (ClientPrefs.downScroll && daNote.y > strumLine.y || !ClientPrefs.downScroll && daNote.y < strumLine.y)
				{
					// Force good note hit regardless if it's too late to hit it or not as a fail safe
					if (cpuControlled && daNote.canBeHit && daNote.mustPress || cpuControlled && daNote.tooLate && daNote.mustPress)
					{
						goodNoteHit(daNote);
						boyfriend.holdTimer = daNote.sustainLength;
					}
				}
			});

			if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true) || cpuControlled))
			{
				if (boyfriend.animation.curAnim.name.startsWith("sing") && !boyfriend.animation.curAnim.name.endsWith("miss"))
					boyfriend.playAnim('idle');
			}

			playerStrums.forEach(function(spr:StrumNote)
			{
				if (controlArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
					if (ClientPrefs.ghostTapping && !cpuControlled && ClientPrefs.ghostTappingBFSing && !boyfriend.specialAnim)
					{
						boyfriend.playAnim(singAnims[spr.ID]);
					}
				}
				if (releaseArray[spr.ID])
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			});
		}
		else if (ClientPrefs.inputType == "Psych 0.4.2")
		{
			// HOLDING
			var up = controls.NOTE_UP;
			var right = controls.NOTE_RIGHT;
			var down = controls.NOTE_DOWN;
			var left = controls.NOTE_LEFT;

			var upP = controls.NOTE_UP_P;
			var rightP = controls.NOTE_RIGHT_P;
			var downP = controls.NOTE_DOWN_P;
			var leftP = controls.NOTE_LEFT_P;

			var upR = controls.NOTE_UP_R;
			var rightR = controls.NOTE_RIGHT_R;
			var downR = controls.NOTE_DOWN_R;
			var leftR = controls.NOTE_LEFT_R;

			var controlArray:Array<Bool> = [leftP, downP, upP, rightP];
			var controlReleaseArray:Array<Bool> = [leftR, downR, upR, rightR];
			var controlHoldArray:Array<Bool> = [left, down, up, right];

			if (!boyfriend.stunned && generatedMusic)
			{
				// rewritten inputs???
				notes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate
						&& !daNote.wasGoodHit)
					{
						goodNoteHit(daNote);
					}
				});

				if ((controlHoldArray.contains(true) || controlArray.contains(true)) && !endingSong)
				{
					var canMiss:Bool = !ClientPrefs.ghostTapping;
					if (controlArray.contains(true))
					{
						for (i in 0...controlArray.length)
						{
							// heavily based on my own code LOL if it aint broke dont fix it
							var pressNotes:Array<Note> = [];
							var notesStopped:Bool = false;

							var sortedNotesList:Array<Note> = [];
							notes.forEachAlive(function(daNote:Note)
							{
								if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && daNote.noteData == i)
								{
									sortedNotesList.push(daNote);
									canMiss = true;
								}
							});
							sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

							if (sortedNotesList.length > 0)
							{
								for (epicNote in sortedNotesList)
								{
									for (doubleNote in pressNotes)
									{
										if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 10)
										{
											doubleNote.kill();
											notes.remove(doubleNote, true);
											doubleNote.destroy();
										}
										else
											notesStopped = true;
									}

									// eee jack detection before was not super good
									if (controlArray[epicNote.noteData] && !notesStopped)
									{
										goodNoteHit(epicNote);
										pressNotes.push(epicNote);
									}
								}
							}
							else if (canMiss)
							{
								if (controlArray[i])
								{
									noteMissPress(i);
								}
							}
						}
					}
				}
				else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
					&& boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				{
					boyfriend.dance();
				}
			}

			playerStrums.forEach(function(spr:StrumNote)
			{
				if (controlArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
					if (ClientPrefs.ghostTapping && !cpuControlled && ClientPrefs.ghostTappingBFSing && !boyfriend.specialAnim)
					{
						boyfriend.playAnim(singAnims[spr.ID]);
					}
				}
				if (controlReleaseArray[spr.ID])
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			});
		}
	}

	function noteMiss(daNote:Note):Void
	{
		if (!boyfriend.stunned)
		{
			notes.forEachAlive(function(note:Note)
			{
				if (daNote != note
					&& daNote.mustPress
					&& daNote.noteData == note.noteData
					&& daNote.isSustainNote == note.isSustainNote
					&& Math.abs(daNote.strumTime - note.strumTime) < 10)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
			});

			switch (daNote.noteType)
			{
				default:
					combo = 0;
					health -= daNote.missHealth;
					songMisses++;
					vocals.volume = 0;
					if (!practiceMode)
						songScore -= 10;

					totalPlayed++;
					RecalculateRating();

					var char:Character = boyfriend;
					if (daNote.gfNote)
						char = gf;

					if (char != null && char.hasMissAnimations)
					{
						var daAlt = '';
						if (daNote.noteType == "Alt Animation")
							daAlt = '-alt';

						if (daNote.noteType == "Bullet Note")
						{
							char.playAnim("hurt", true);
							return;
						}

						char.playAnim(singAnims[Std.int(Math.abs(daNote.noteData)) % 4] + "miss" + daAlt, true);
					}
					
					if (ClientPrefs.missVolume > 0)
						FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), ClientPrefs.missVolume);
			}
		}
	}

	function noteMissPress(direction:Int = 1):Void
	{
		if (!boyfriend.stunned)
		{
			health -= 0.05;
			combo = 0;

			if (!practiceMode)
				songScore -= 10;
			if (!endingSong)
				songMisses++;
			totalPlayed++;
			RecalculateRating();

			var char:Character = boyfriend;

			if (char != null && char.hasMissAnimations)
				char.playAnim(singAnims[direction] + "miss", true);

			vocals.volume = 0;
			if (ClientPrefs.missVolume > 0)
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), ClientPrefs.missVolume);
		}
	}

	function goodNoteHit(note:Note, released:Bool = false):Void // i hate myself
	{
		if (!note.wasGoodHit)
		{
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);

			if (!note.isSustainNote || released && note.isLiftNote)
			{
				combo += 1;
				popUpScore(note);
				if (combo > 9999)
					combo = 9999;
			}

			health += note.hitHealth;

			if (!note.noAnimation)
			{
				var char:Character = boyfriend;
				var daAlt = '';
				if (note.noteType == "Alt Animation")
					daAlt = '-alt';

				if (note.gfNote)
					char = gf;

				if (char != null && !(released && note.isLiftNote))
				{
					switch(note.noteType)
					{
						case "Bullet Note":
							dad.playAnim(singAnims[Std.int(Math.abs(note.noteData)) % 4].replace("sing", "") + "shoot", true);
							boyfriend.playAnim('dodge', true);
							
							boyfriend.specialAnim = true;
							dad.specialAnim = true;

							FlxG.camera.shake(0.01, 0.2);

							if(CoolUtil.difficulties[storyDifficulty] == "FUCKED")
								FlxG.sound.play(Paths.sound('hankshoot', "AccelerantAssets"));
						default:
							char.playAnim(singAnims[Std.int(Math.abs(note.noteData)) % 4] + daAlt, true);
							char.holdTimer = 0;
					}
				}

				if (note.noteType == "Hey!")
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
					time += 0.15;
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			}
			else
			{
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
						spr.playAnim('confirm', true);
				});
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				if (cpuControlled)
					boyfriend.holdTimer = 0;
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
			else if (cpuControlled)
			{
				var targetHold:Float = Conductor.stepCrochet * 0.001 * boyfriend.singDuration;
				if (boyfriend.holdTimer + 0.2 > targetHold)
					boyfriend.holdTimer = targetHold - 0.2;
			}
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (note.noteType == 'Hey!' && boyfriend.animOffsets.exists('hey'))
		{
			boyfriend.playAnim('hey', true);
			boyfriend.specialAnim = true;
			boyfriend.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation')
					altAnim = '-alt';
			}

			var char:Character = dad;

			if (note.gfNote)
				char = gf;

			if (char != null)
			{
				char.playAnim(singAnims[Std.int(Math.abs(note.noteData)) % 4] + altAnim, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
			time += 0.15;
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		if (!note.isSustainNote)
		{
			if (!ClientPrefs.middleScroll && ClientPrefs.opponentNoteSplash)
				spawnNoteSplashOnNote(note, true);
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function spawnNoteSplashOnNote(note:Note, isDad:Bool = false)
	{
		if (ClientPrefs.noteSplashes && note != null)
		{
			var strum:StrumNote = null;
			if (isDad)
				strum = opponentStrums.members[note.noteData];
			else
				strum = playerStrums.members[note.noteData];

			if (strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String = 'noteSplashes';
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if (note != null)
		{
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	override function destroy()
	{
		super.destroy();
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if (curStep == lastStepHit)
		{
			return;
		}

		switch(curStage)
		{
			case "nevada":
				switch(curStep)
				{
					case 16:
						defaultCamZoom = 0.6;
						FlxG.sound.play(Paths.sound('hankreadyupsound', "AccelerantAssets"));
						FlxTween.tween(camGame, {zoom: 0.6}, 0.3, { ease: FlxEase.circInOut });
				}
		}

		lastStepHit = curStep;
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
		{
			trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			openfl.system.System.gc();
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				FlxG.log.add("BPM Change, new BPM: " + SONG.notes[Math.floor(curStep / 16)].bpm);
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			}
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null
			&& curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& !gf.stunned
			&& gf.animation.curAnim.name != null
			&& !gf.animation.curAnim.name.startsWith("sing")
			&& !gf.stunned)
		{
			// taken from the pe-0.4.2 android thingy
			if (ClientPrefs.iconBoping)
			{
				if (curBeat % gfSpeed == 0)
				{
					curBeat % (gfSpeed * 2) == 0 ? {
						iconP1.scale.set(1.1, 0.8);
						iconP2.scale.set(1.1, 1.3);

						FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
					} : {
						iconP1.scale.set(1.1, 1.3);
						iconP2.scale.set(1.1, 0.8);

						FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						}

					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});

					iconP1.updateHitbox();
					iconP2.updateHitbox();
				}
			}
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0
			&& boyfriend.animation.curAnim != null
			&& !boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0
			&& dad.animation.curAnim != null
			&& !dad.animation.curAnim.name.startsWith('sing')
			&& !dad.stunned)
		{
			dad.dance();
		}

		lastBeatHit = curBeat;
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = null;
		if (isDad)
		{
			spr = opponentStrums.members[id];
		}
		else
		{
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingString:String;
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating()
	{
		if (totalPlayed < 1)
		{
			switch (ClientPrefs.scoreTextDesign)
			{
				case 'Engine':
					ratingString = "N/A";
				case 'Psych':
					ratingString = "?";
			}
		}
		else
		{
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
			if (ratingPercent >= 1)
			{
				ratingString = ratingStuff[ratingStuff.length - 1][0];
			}
			else
			{
				for (i in 0...ratingStuff.length - 1)
				{
					if (ratingPercent < ratingStuff[i][1])
					{
						ratingString = ratingStuff[i][0];
						break;
					}
				}
			}
		}

		ratingFC = "";
		if (sicks > 0)
			ratingFC = "SFC";
		if (goods > 0)
			ratingFC = "GFC";
		if (bads > 0 || shits > 0)
			ratingFC = "FC";
		if (songMisses > 0 && songMisses < 10)
			ratingFC = "SDCB";
		else if (songMisses >= 10)
			ratingFC = "Clear";
	}

	function getScoreTextFormat():String
	{
		switch (ClientPrefs.scoreTextDesign)
		{
			case 'Engine':
				if (ratingString == 'N/A')
				{
					return 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | ' + ratingString;
				}
				else
				{
					return 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Accuracy: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%'
						+ ' | ' + ratingString + ' (' + ratingFC + ')';
				}
			case 'Psych':
				if (ratingString == '?')
				{
					return 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingString;
				}
				else
				{
					return 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingString + ' ('
						+ Highscore.floorDecimal(ratingPercent * 100, 2) + '%) - ' + ratingFC;
				}
		}
		return "";
	}

	// no way is this from sonic.exe v2.5?????¿?¿?!?!?!??!?=?=?=?!?!1
	function cameraDisplacement(character:Character, mustHit:Bool)
	{
		if (ClientPrefs.cameraMovement)
		{
			if (SONG.notes[Std.int(curStep / 16)] != null)
			{
				if (SONG.notes[Std.int(curStep / 16)].mustHitSection
					&& mustHit
					|| (!SONG.notes[Std.int(curStep / 16)].mustHitSection && !mustHit))
				{
					if (character.animation.curAnim != null)
					{
						camDisplaceX = 0;
						camDisplaceY = 0;
						switch (character.animation.curAnim.name)
						{
							case 'singUP':
								camDisplaceY -= ClientPrefs.cameraMovementDisplacement;
							case 'singDOWN':
								camDisplaceY += ClientPrefs.cameraMovementDisplacement;
							case 'singLEFT':
								camDisplaceX -= ClientPrefs.cameraMovementDisplacement;
							case 'singRIGHT':
								camDisplaceX += ClientPrefs.cameraMovementDisplacement;

							//funky - move to the opposite direction as it missed, would be cool to get the note direction to move in that direction lol
							case 'singUPmiss':
								camDisplaceY += ClientPrefs.cameraMovementDisplacement;
							case "singDOWNmiss":
								camDisplaceY -= ClientPrefs.cameraMovementDisplacement;
							case "singLEFTmiss":
								camDisplaceX += ClientPrefs.cameraMovementDisplacement;
							case "singRIGHTmiss":
								camDisplaceX -= ClientPrefs.cameraMovementDisplacement;
						}
					}
				}
			}
		}
	}

	function updateCamFollow(?elapsed:Float)
	{
		if (elapsed == null)
			elapsed = FlxG.elapsed;
		if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
		{
			var char = dad;

			var getCenterX = char.getMidpoint().x + 150;
			var getCenterY = char.getMidpoint().y - 100;

			camFollow.set(getCenterX, getCenterY);

			camFollow.x += camDisplaceX + char.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += camDisplaceY + char.cameraPosition[1] + opponentCameraOffset[1];
		}
		else
		{
			var char = boyfriend;

			var getCenterX = char.getMidpoint().x - 100;
			var getCenterY = char.getMidpoint().y - 100;

			camFollow.set(getCenterX, getCenterY);

			camFollow.x += camDisplaceX - char.cameraPosition[0] + boyfriendCameraOffset[0];
			camFollow.y += camDisplaceY + char.cameraPosition[1] + boyfriendCameraOffset[1];
		}
	}

	// goofy fix for the cutscene camera
	function focusCamera(isDad:Bool = false)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
		}
	}
}
