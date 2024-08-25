/**

Texture selection macro scheme for connecting together effects in a completely modular way controlled
by the preset. User input is held at an effect defined macro where they can invoke a `referrer` which then
can expand a `function` in another macro.
For example:

MY_EFFECT_TEXTURE = Texture(texSomeVelocity)
or
MY_EFFECT_TEXTURE = LaunchPad()
MY_EFFECT_TEXTURE = LaunchPad_Old()
MY_EFFECT_TEXTURE = Retained()

The rest is for effect developers:
In the effect code there can be many function macros declared with the input referrer:

#define Declare_Texture(name) ...
#define Use_Texture(name) ...
#define Magic_Texture(name) ...

which is then selected via the REFERRER macro, for example:

REFERRER(Declare, MY_EFFECT_TEXTURE)

*/

#ifndef __DEFAULT_TEXTURE_FORMAT
#define __DEFAULT_TEXTURE_FORMAT RGB10A2
#endif

#define Declare_Texture(name) texture name { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = __DEFAULT_TEXTURE_FORMAT; };
#define Use_Texture(name) name

#define Declare_NamespaceTexture(ns, name) namespace ns { Declare_Texture(name) }
#define Use_NamespaceTexture(ns, name) ns::name

#define REFERRER_IMPL_0(function, referrer) function##_##referrer
#define REFERRER(function, referrer) REFERRER_IMPL_0(function, referrer)