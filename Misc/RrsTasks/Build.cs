using System;
using System.Linq;
using System.Text.RegularExpressions;
using JetBrains.Annotations;
using Nuke.Cola;
using Nuke.Cola.FolderComposition;
using Nuke.Common;
using Nuke.Common.IO;
using Nuke.Common.Utilities;

class Build : NukeBuild
{
    /// Support plugins are available for:
    ///   - JetBrains ReSharper        https://nuke.build/resharper
    ///   - JetBrains Rider            https://nuke.build/rider
    ///   - Microsoft VisualStudio     https://nuke.build/visualstudio
    ///   - Microsoft VSCode           https://nuke.build/vscode

    public static int Main () => Execute<Build>(x => x.Gather);

    [Parameter] [NotNull] readonly DllName Dll = DllName.DXGI;
    [Parameter] [NotNull] readonly Architecture Arch = Architecture.X64;
    [Parameter] readonly bool DgVoodoo = false;
    [Parameter] [CanBeNull] readonly AbsolutePath Exe;
    [Parameter] [CanBeNull] readonly string Subdir;

    string EffectPaths;
    string TexturePaths;

    Target Gather => _ => _
        .Executes(() =>
        {
            var addonsLink = new ExportManifest
            {
                Link =
                {
                    new() { File = "**/*.addon*", As = "$2.addon$3"}
                }
            };

            var dst = RootDirectory / "reshade-shaders";
            dst.DeleteDirectory();
            var dstShaders = dst / "Shaders";
            var dstTextures = dst / "Textures";
            var dstAddons = dst / "Addons";

            this.ImportFolders(
                new ImportOptions(UseSubfolder: false),
                (RootDirectory.Parent / "Shaders",                                               dstShaders / "microdee"              ),
                (RootDirectory / "Public/Submodules/METEOR/Shaders",                             dstShaders / "METEOR"                ),
                (RootDirectory / "Public/Submodules/Vanilla/Shaders",                            dstShaders / "Vanilla"               ),
                (RootDirectory / "Public/Submodules/AcerolaFX/Shaders",                          dstShaders / "AcerolaFX"             ),
                (RootDirectory / "Public/Submodules/AgXc/reshade/reshade-shaders/Shaders",       dstShaders / "AgXc"                  ),
                (RootDirectory / "Public/Submodules/AstrayFX/Shaders",                           dstShaders / "AstrayFX"              ),
                (RootDirectory / "Public/Submodules/brussell1/Shaders",                          dstShaders / "brussell1"             ),
                (RootDirectory / "Public/Submodules/CobraFX/Shaders",                            dstShaders / "CobraFX"               ),
                (RootDirectory / "Public/Submodules/CShade/Shaders",                             dstShaders / "CShade"                ),
                (RootDirectory / "Public/Submodules/crt-royale-reshade/reshade-shaders/Shaders", dstShaders / "crt-royale-reshade"    ),
                (RootDirectory / "Public/Submodules/Daodan/Shaders",                             dstShaders / "Daodan"                ),
                (RootDirectory / "Public/Submodules/fubax-shaders/Shaders",                      dstShaders / "fubax-shaders"         ),
                (RootDirectory / "Public/Submodules/Insane-Shaders/Shaders",                     dstShaders / "Insane-Shaders"        ),
                (RootDirectory / "Public/Submodules/Luluco250_FXShaders/Shaders",                dstShaders / "Luluco250_FXShaders"   ),
                (RootDirectory / "Public/Submodules/NiceGuy-Shaders/Shaders",                    dstShaders / "NiceGuy-Shaders"       ),
                (RootDirectory / "Public/Submodules/OtisFX/Shaders",                             dstShaders / "OtisFX"                ),
                (RootDirectory / "Public/Submodules/prod80-ReShade-Repository/Shaders",          dstShaders / "prod80"                ),
                (RootDirectory / "Public/Submodules/reshade-unity-shaders/Shaders",              dstShaders / "reshade-unity-shaders" ),
                (RootDirectory / "Public/Submodules/RSRetroArch/Shaders",                        dstShaders / "RSRetroArch"           ),
                (RootDirectory / "Public/Submodules/SweetFX/Shaders",                            dstShaders / "SweetFX"               ),
                (RootDirectory / "Public/Submodules/YASSGI/Shaders",                             dstShaders / "YASSGI"                ),
                (RootDirectory / "Public/AmbientLight/Shaders",                                  dstShaders / "AmbientLight"          ),
                (RootDirectory / "Public/REST",                                                  dstShaders / "REST"                  ),
                (RootDirectory / "Private/ImmerseUltimate/Shaders/iMMERSE",                      dstShaders / "ImmerseUltimate"       ),

                (RootDirectory.Parent / "Textures",                                         dstTextures / "microdee"              ),
                (RootDirectory / "Public/Submodules/METEOR/Textures",                       dstTextures / "METEOR"                ),
                (RootDirectory / "Public/Submodules/Vanilla/Textures",                      dstTextures / "Vanilla"               ),
                (RootDirectory / "Public/Submodules/AcerolaFX/Textures",                    dstTextures / "AcerolaFX"             ),
                (RootDirectory / "Public/Submodules/AgXc/reshade/reshade-shaders/Textures", dstTextures / "AgXc"                  ),
                (RootDirectory / "Public/Submodules/AstrayFX/Textures",                     dstTextures / "AstrayFX"              ),
                (RootDirectory / "Public/Submodules/brussell1/Textures",                    dstTextures / "brussell1"             ),
                (RootDirectory / "Public/Submodules/CobraFX/Textures",                      dstTextures / "CobraFX"               ),
                (RootDirectory / "Public/Submodules/Daodan/Textures",                       dstTextures / "Daodan"                ),
                (RootDirectory / "Public/Submodules/fubax-shaders/Textures",                dstTextures / "fubax-shaders"         ),
                (RootDirectory / "Public/Submodules/Luluco250_FXShaders/Textures",          dstTextures / "Luluco250_FXShaders"   ),
                (RootDirectory / "Public/Submodules/NiceGuy-Shaders/Textures",              dstTextures / "NiceGuy-Shaders"       ),
                (RootDirectory / "Public/Submodules/OtisFX/Textures",                       dstTextures / "OtisFX"                ),
                (RootDirectory / "Public/Submodules/prod80-ReShade-Repository/Textures",    dstTextures / "prod80"                ),
                (RootDirectory / "Public/Submodules/reshade-unity-shaders/Textures",        dstTextures / "reshade-unity-shaders" ),
                (RootDirectory / "Public/Submodules/RSRetroArch/Textures",                  dstTextures / "RSRetroArch"           ),
                (RootDirectory / "Public/Submodules/SweetFX/Textures",                      dstTextures / "SweetFX"               ),
                (RootDirectory / "Public/Submodules/YASSGI/Textures",                       dstTextures / "YASSGI"                ),
                (RootDirectory / "Public/AmbientLight/Textures",                            dstTextures / "AmbientLight"          ),
                (RootDirectory / "Private/ImmerseUltimate/Textures/iMMERSE",                dstTextures / "ImmerseUltimate"       ),

                (RootDirectory / "Public/REST",                    dstAddons, addonsLink),
                (RootDirectory / "Private/ImmerseUltimate/Addons", dstAddons, addonsLink),
                (RootDirectory / "Private/Addons",                 dstAddons, addonsLink)
            );

            EffectPaths = dstShaders.GetDirectories().Select(d => @".\reshade-shaders\Shaders\" + d.Name).JoinComma();
            TexturePaths = dstShaders.GetDirectories().Select(d => @".\reshade-shaders\Textures\" + d.Name).JoinComma();

            var reshadeIniPath = RootDirectory / "ReShade.ini";
            var reshadeIni = reshadeIniPath.ReadAllText()
                .ReplaceRegex("EffectSearchPaths=*.$", _ => "EffectSearchPaths=" + EffectPaths, RegexOptions.Multiline)
                .ReplaceRegex("TextureSearchPaths=*.$", _ => "TextureSearchPaths=" + TexturePaths, RegexOptions.Multiline)
            ;
            reshadeIniPath.WriteAllText(reshadeIni);
        });

    Target Install => _ => _
        .Requires(() => Exe)
        .Requires(() => Arch)
        .DependsOn(Gather)
        .Executes(() =>
        {
            var dllName = DgVoodoo ? "dxgi.dll" : Dll.GetDllName(Arch);
            var reshadeDllSrc = RootDirectory / "Private/Reshade" / ("ReShade" + Arch.Bits + ".dll");
            var dgVoodooDllSrc = RootDirectory / "Private/DgVoodoo/MS" / Arch / (Dll + ".dll");
            
            var binFolder = Subdir == null ? Exe!.Parent : Exe!.Parent / Subdir;
            var reshadeDst = DgVoodoo
                ? Exe.Parent / "reshade-shaders"
                : binFolder / "reshade-shaders"
            ;

            reshadeDst.LinksDirectory(RootDirectory / "reshade-shaders");
            if (DgVoodoo)
            {
                this.ImportFolder(
                    new(RootDirectory / "Private/DgVoodoo", binFolder!, new ExportManifest
                    {
                        Link =
                        {
                            new() { File = $"MS/{Arch.ToString().ToLower()}/{Dll.GetDllName(Arch)}", As = Dll.GetDllName(Arch)},
                            new() { File = "dgVoodooCpl.exe" },
                        },
                        Copy =
                        {
                            new() { File = "dgVoodoo.conf" }
                        }
                    }),
                    new(UseSubfolder: false)
                );

                (Exe.Parent / dllName).LinksFile(reshadeDllSrc);
                (Exe.Parent / "dgVoodoo.conf").LinksFile(binFolder / "dgVoodoo.conf");
                (Exe.Parent / "dgVoodooCpl.exe").LinksFile(binFolder / "dgVoodooCpl.exe");
            }
            else
            {
                (binFolder / dllName).LinksFile(reshadeDllSrc);
            }

            var reshadeIniDstPath = reshadeDst.Parent / "ReShade.ini";
            (RootDirectory / "ReShade.ini").Copy(reshadeIniDstPath, ExistsPolicy.FileSkip);
            var reshadeIni = reshadeIniDstPath.ReadAllText()
                .ReplaceRegex("EffectSearchPaths=*.$", _ => "EffectSearchPaths=" + EffectPaths, RegexOptions.Multiline)
                .ReplaceRegex("TextureSearchPaths=*.$", _ => "TextureSearchPaths=" + TexturePaths, RegexOptions.Multiline)
            ;
            reshadeIniDstPath.WriteAllText(reshadeIni);

            (RootDirectory / "Template.ini").CopyToDirectory(reshadeDst.Parent, ExistsPolicy.FileSkip);

            this.ImportFolder(
                new(reshadeDst / "Addons", reshadeDst.Parent!, new ExportManifest
                {
                    Link =
                    {
                        new() { File = "*.addon" + Arch.Bits }
                    }
                }),
                new(UseSubfolder: false)
            );
        });
}
