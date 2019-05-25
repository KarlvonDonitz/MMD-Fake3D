#define AA_FLG 0
//edit by KarlvonDonitz

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

float XValue : CONTROLOBJECT < string name = "(self)"; string item = "X";>;
float YValue : CONTROLOBJECT < string name = "(self)"; string item = "Y";>;
float XBais : CONTROLOBJECT < string name = "(self)"; string item = "Rx";>;
float Intensity : CONTROLOBJECT < string name = "(self)"; string item = "Si";>;

float2 ViewportSize : VIEWPORTPIXELSIZE;


float4 ClearColor = {0,0,0,1};
float ClearDepth  = 1.0;


texture2D ScnMap : RENDERCOLORTARGET <

    int MipLevels = 1;
    bool AntiAlias = AA_FLG;
    string Format = "A8R8G8B8" ;
>;
sampler2D ScnSamp = sampler_state {
    texture = <ScnMap>;
    AddressU  = CLAMP;
    AddressV = CLAMP;
    Filter = NONE;
};

texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    string Format = "D24S8";
>;

texture LinearMask: OFFSCREENRENDERTARGET <
    string Description = "Mask for Fake3D.fx";
    float4 ClearColor = { 0, 0, 0, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = 0;
    string DefaultEffect = 
        "* = depth.fx";
>;

sampler Mask = sampler_state {
	texture = <LinearMask>;
	AddressU = CLAMP;
	AddressV = CLAMP;
	Filter = NONE;
};


struct VS_OUTPUT {
    float4 Pos			: POSITION;
	float2 Tex			: TEXCOORD0;
};


VS_OUTPUT VS_passMain( float4 Pos : POSITION, float4 Tex : TEXCOORD0 ){
    VS_OUTPUT Out = (VS_OUTPUT)0; 

    Out.Pos = Pos; 
    Out.Tex = Tex;
    return Out;
}

float4 PS_passMain(float2 Tex: TEXCOORD0) : COLOR
{   
	float4 TexColor = tex2D(ScnSamp,Tex);
	float4 Color = float4(0,0,0,1);
	if ( tex2D(Mask,Tex).r > 0  ) Color = 1-tex2D(Mask,Tex).r;
	float Flag = 1-tex2D(Mask,Tex).r;
	Color = TexColor;
	float YFlag = YValue/ViewportSize.y;
	float XFlag = (ViewportSize.x/XValue)/ViewportSize.x;
	float Bais = XBais*10/ViewportSize.x;
	for ( float i=1;i<XValue;i++) 
	{
	if ( Tex.x > i*XFlag-Bais  && Tex.x < i*XFlag+Bais ) Color=float4(0,0,0,1);
	}
	if(Tex.y < YFlag || 1-Tex.y < YFlag) Color = float4(0,0,0,1);
	if (Flag > 0.95 ) Color=TexColor;
	return Color;
}

technique Color <
    string Script = 
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "ScriptExternal=Color;"
        
        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "Pass=Main;"
    ;
> {

    pass Main < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passMain();
        PixelShader  = compile ps_3_0 PS_passMain();
    }
}
