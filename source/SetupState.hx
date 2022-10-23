package;

import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;

class SetupState extends MusicBeatState
{
    public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	static var goPreload:Bool = false;

    override public function create()
    {
        FlxG.game.focusLostFramerate = 30;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.mouse.visible = false;

		PlayerSettings.init();

        FlxG.save.bind('funkin', 'ninjamuffin99');
		ClientPrefs.loadPrefs();

		Highscore.load();

		switch(ClientPrefs.selectedMod)
		{
			case "base":
				goPreload = false;
				ClientPrefs.modDirectory = "";
			case "Malediction":
				goPreload = true;
				ClientPrefs.modDirectory = "Malediction";
		}

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		
		if(goPreload == false)
			MusicBeatState.switchState(new TitleState());
		else
			PreloadState.loadAndSwitchState(new TitleState());

        super.create();
    }
}