/**

Texture selection macro scheme for connecting together effects in a completely modular way controlled
by the preset. User input is held at VELOCITY_TEXTURE where they can invoke a `referrer` which then
can expand a `function` in another macro.
For example:

VELOCITY_TEXTURE = Texture(texSomeVelocity)
or
VELOCITY_TEXTURE = LaunchPad()
VELOCITY_TEXTURE = LaunchPad_Old()
VELOCITY_TEXTURE = Retained()

The rest is for effect developers:
In the effect code there can be many function macros declared with the input referrer:

#define Declare_Texture(name) ...
#define Use_Texture(name) ...
#define Magic_Texture(name) ...

which is then selected via the REFERRER macro, for example:

REFERRER(Declare, VELOCITY_TEXTURE)

*/

#define __DEFAULT_TEXTURE_FORMAT RG16F
#include "ReferrerMacroScheme.fxh"

#ifndef __VELOCITY_SAMPLER
#define __VELOCITY_SAMPLER(texture) sMotionVectorTex { Texture = texture; }
#endif

#ifndef __DEFAULT_VELOCITY_TEXTURE
#define __DEFAULT_VELOCITY_TEXTURE LaunchPad()
#endif

#ifndef VELOCITY_TEXTURE
#define VELOCITY_TEXTURE __DEFAULT_VELOCITY_TEXTURE
#endif

#define Declare_LaunchPad() Declare_NamespaceTexture(Deferred, MotionVectorsTex)
#define Use_LaunchPad() Use_NamespaceTexture(Deferred, MotionVectorsTex)

#define Declare_LaunchPad_Old() Declare_NamespaceTexture(Velocity, OldMotionVectorsTex)
#define Use_LaunchPad_Old() Use_NamespaceTexture(Velocity, OldMotionVectorsTex)

#define Declare_Retained() Declare_Texture(texRetainedVelocity)
#define Use_Retained() texRetainedVelocity

#define DECLARE_VELOCITY REFERRER(Declare, VELOCITY_TEXTURE)

#define USE_VELOCITY REFERRER(Use, VELOCITY_TEXTURE)

DECLARE_VELOCITY;
sampler __VELOCITY_SAMPLER(USE_VELOCITY);