package;

import flixel.FlxG;
import flixel.util.FlxColor;

class TitleState extends base.TitleStateBase
{
	override public function create()
	{
		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.TWO)
		{
			ClientPrefs.selectedMod = "Malediction";

			initialized = false;
			closedState = false;

			ClientPrefs.saveSettings();

			FlxG.mouse.visible = true;

			FlxG.sound.music.fadeOut(0.3);
			Main.tweenFPS(false, 0.5);
			Main.tweenMemory(false, 0.5);
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
		}
	}
}
