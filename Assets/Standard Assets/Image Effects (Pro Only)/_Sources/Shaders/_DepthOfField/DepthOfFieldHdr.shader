 Shader "Hidden/Dof/DepthOfFieldHdr" {
	Properties {
		_MainTex ("-", 2D) = "" {}
		_MainTex2 ("-", 2D) = "" {}
		_TapLowA ("-", 2D) = "" {}
		_TapLowB ("-", 2D) = "" {}
		_TapLowC ("-", 2D) = "" {}
	}

	CGINCLUDE
	
	#include "UnityCG.cginc"
	
	struct v2f {
		half4 pos : POSITION;
		half2 uv1 : TEXCOORD0;
	};
	
	struct v2fDofApply {
		half4 pos : POSITION;
		half2 uv : TEXCOORD0;
	};
	
	struct v2fRadius {
		half4 pos : POSITION;
		half2 uv : TEXCOORD0;
		half4 uv1[4] : TEXCOORD1;
	};
	
	struct v2fDown {
		half4 pos : POSITION;
		half2 uv0 : TEXCOORD0;
		half2 uv[2] : TEXCOORD1;
	};	 
	
	struct v2fBlur {
		half4 pos : POSITION;
		half2 uv : TEXCOORD0;
		half4 uv01 : TEXCOORD1;
		half4 uv23 : TEXCOORD2;
		half4 uv45 : TEXCOORD3;
		half4 uv67 : TEXCOORD4;
		half4 uv89 : TEXCOORD5;
	};	
	
	struct mrtOut {
		half4 color0 : COLOR0;
		half4 color1 : COLOR1;
	};
			
	sampler2D _MainTex;
	sampler2D _MainTex2;
	sampler2D _TapLowA;	
	sampler2D _TapLowB;
	sampler2D _TapLowC;
	sampler2D _CameraDepthTexture;
	
	half4 _CurveParams;
	uniform float4 _MainTex_TexelSize;
	uniform float2 _InvRenderTargetSize;
	
	uniform half4 _Offsets;
	uniform half4 _Offsets2;
	
	v2f vert( appdata_img v ) {
		v2f o;
		o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
		o.uv1.xy = v.texcoord.xy;
		return o;
	} 

	v2fBlur vertBlur (appdata_img v) {
		v2fBlur o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv.xy = v.texcoord.xy;
		o.uv01 =  v.texcoord.xyxy + _Offsets.xyxy * half4(1,1, 2,2);
		o.uv23 =  v.texcoord.xyxy + _Offsets.xyxy * half4(3,3, 4,4);// * 3.0;
		o.uv45 =  v.texcoord.xyxy + _Offsets.xyxy * half4(5,5, 6,6);// * 3.0;
		o.uv67 =  v.texcoord.xyxy + _Offsets.xyxy * half4(7,7, 8,8);// * 4.0;
		o.uv89 =  v.texcoord.xyxy + _Offsets.xyxy * half4(9,9, 10,10);// * 5.0;
		return o;  
	}

	v2fBlur vertBlurPlusMinus (appdata_img v) {
		v2fBlur o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv.xy = v.texcoord.xy;
		o.uv01 =  v.texcoord.xyxy + _Offsets.xyxy * half4(1,1, -1,-1);
		o.uv23 =  v.texcoord.xyxy + _Offsets.xyxy * half4(2,2, -2,-2);// * 3.0;
		o.uv45 =  v.texcoord.xyxy + _Offsets.xyxy * half4(3,3, -3,-3);// * 3.0;
		o.uv67 =  v.texcoord.xyxy + _Offsets.xyxy * half4(4,4, -4,-4);// * 4.0;
		o.uv89 =  v.texcoord.xyxy + _Offsets.xyxy * half4(5,5, -5,-5);// * 5.0;
		return o;  
	}

	v2fRadius vertWithRadius( appdata_img v ) {
		v2fRadius o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv.xy = v.texcoord.xy;

		const half2 blurOffsets[4] = {
			half2(-0.5, +1.5),
			half2(+0.5, -1.5),
			half2(+1.5, +0.5),
			half2(-1.5, -0.5)
		}; 	
				
		o.uv1[0].xy = v.texcoord.xy + 5.0 * _MainTex_TexelSize.xy * blurOffsets[0];
		o.uv1[1].xy = v.texcoord.xy + 5.0 * _MainTex_TexelSize.xy * blurOffsets[1];
		o.uv1[2].xy = v.texcoord.xy + 5.0 * _MainTex_TexelSize.xy * blurOffsets[2];
		o.uv1[3].xy = v.texcoord.xy + 5.0 * _MainTex_TexelSize.xy * blurOffsets[3];
		
		o.uv1[0].zw = v.texcoord.xy + 3.0 * _MainTex_TexelSize.xy * blurOffsets[0];
		o.uv1[1].zw = v.texcoord.xy + 3.0 * _MainTex_TexelSize.xy * blurOffsets[1];
		o.uv1[2].zw = v.texcoord.xy + 3.0 * _MainTex_TexelSize.xy * blurOffsets[2];
		o.uv1[3].zw = v.texcoord.xy + 3.0 * _MainTex_TexelSize.xy * blurOffsets[3];
		
		return o;
	} 
	
	v2fDofApply vertDofApply( appdata_img v ) {
		v2fDofApply o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv.xy = v.texcoord.xy;
		return o;
	} 	
		
	v2fDown vertDownsampleWithCocConserve(appdata_img v) {
		v2fDown o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);	
		o.uv0.xy = v.texcoord.xy;
		o.uv[0].xy = v.texcoord.xy + half2(-1.0,-1.0) * _InvRenderTargetSize;
		o.uv[1].xy = v.texcoord.xy + half2(1.0,-1.0) * _InvRenderTargetSize;		
		return o; 
	} 
	
	half4 BokehPrereqs (sampler2D tex, half4 uv1[4], half4 center, half considerCoc) {		
		
		// @NOTE 1:
		// we are checking for 3 things in order to create a bokeh.
		// goal is to get the highest bang for the buck.
		// 1.) contrast/frequency should be very high (otherwise bokeh mostly unvisible)
		// 2.) luminance should be high
		// 3.) no occluder nearby (stored in alpha channel)
		
		// @NOTE 2: about the alpha channel in littleBlur:
		// the alpha channel stores an heuristic on how likely it is 
		// that there is no bokeh occluder nearby.
		// if we didn't' check for that, we'd get very noise bokeh
		// popping because of the sudden contrast changes

		half4 sampleA = tex2D(tex, uv1[0].zw);
		half4 sampleB = tex2D(tex, uv1[1].zw);
		half4 sampleC = tex2D(tex, uv1[2].zw);
		half4 sampleD = tex2D(tex, uv1[3].zw);
		
		half4 littleBlur = 0.125 * (sampleA + sampleB + sampleC + sampleD);
		
		sampleA = tex2D(tex, uv1[0].xy);
		sampleB = tex2D(tex, uv1[1].xy);
		sampleC = tex2D(tex, uv1[2].xy);
		sampleD = tex2D(tex, uv1[3].xy);		

		littleBlur += 0.125 * (sampleA + sampleB + sampleC + sampleD);
				
		littleBlur = lerp (littleBlur, center, saturate(100.0 * considerCoc * abs(littleBlur.a - center.a)));
				
		return littleBlur;
	}	
	
	half4 fragDownsampleWithCocConserve(v2fDown i) : COLOR {
		half2 rowOfs[4];   
		
  		rowOfs[0] = half2(0.0, 0.0);  
  		rowOfs[1] = half2(0.0, _InvRenderTargetSize.y);  
  		rowOfs[2] = half2(0.0, _InvRenderTargetSize.y) * 2.0;  
  		rowOfs[3] = half2(0.0, _InvRenderTargetSize.y) * 3.0; 
  		
  		half4 color = tex2D(_MainTex, i.uv0.xy); 	
			
		half4 sampleA = tex2D(_MainTex, i.uv[0].xy + rowOfs[0]);  
		half4 sampleB = tex2D(_MainTex, i.uv[1].xy + rowOfs[0]);  
		half4 sampleC = tex2D(_MainTex, i.uv[0].xy + rowOfs[2]);  
		half4 sampleD = tex2D(_MainTex, i.uv[1].xy + rowOfs[2]);  
		
		color += sampleA + sampleB + sampleC + sampleD;
		color *= 0.2;
		
		// @NOTE we are doing max on the alpha channel for 2 reasons:
		// 1) foreground blur likes a slightly bigger radius
		// 2) otherwise we get an ugly outline between high blur- and medium blur-areas
		// drawback: we get a little bit of color bleeding  		
		
		color.a = max(max(sampleA.a, sampleB.a), max(sampleC.a, sampleD.a));
  		
		return color;
	}
	
	half4 fragBlur9Tap (v2fBlur i) : COLOR 
	{
		half4 blurredColor = half4 (0,0,0,0);

		half4 sampleA = tex2D(_MainTex, i.uv.xy);
		half4 sampleB = tex2D(_MainTex, i.uv01.xy);
		half4 sampleC = tex2D(_MainTex, i.uv01.zw);
		half4 sampleD = tex2D(_MainTex, i.uv23.xy);
		half4 sampleE = tex2D(_MainTex, i.uv23.zw);
		half4 sampleF = tex2D(_MainTex, i.uv45.xy);
		half4 sampleG = tex2D(_MainTex, i.uv45.zw);
		half4 sampleH = tex2D(_MainTex, i.uv67.xy);
		half4 sampleI = tex2D(_MainTex, i.uv67.zw);
		half4 sampleJ = tex2D(_MainTex, i.uv89.xy);
		half4 sampleK = tex2D(_MainTex, i.uv89.zw);
										
		blurredColor += sampleA;
		blurredColor += sampleB;
		blurredColor += sampleC; 
		blurredColor += sampleD; 
		blurredColor += sampleE; 
		blurredColor += sampleF; 
		blurredColor += sampleG; 
		blurredColor += sampleH; 
		blurredColor += sampleI; 
		blurredColor += sampleJ; 
		blurredColor += sampleK; 
								
		blurredColor = blurredColor / 9;
		
		return blurredColor;
	}	
	
	half4 fragBlur9TapGauss (v2fBlur i) : COLOR 
	{
		half4 blurredColor = half4 (0,0,0,0);

		half4 sampleA = tex2D(_MainTex, i.uv.xy)*3;
		half4 sampleB = tex2D(_MainTex, i.uv01.xy)*2.0;
		half4 sampleC = tex2D(_MainTex, i.uv01.zw)*2.0;
		half4 sampleD = tex2D(_MainTex, i.uv23.xy)*1.5;
		half4 sampleE = tex2D(_MainTex, i.uv23.zw)*1.5; //12
		half4 sampleF = tex2D(_MainTex, i.uv45.xy)*0.75;
		half4 sampleG = tex2D(_MainTex, i.uv45.zw)*0.75;
		half4 sampleH = tex2D(_MainTex, i.uv67.xy)*0.25;
		half4 sampleI = tex2D(_MainTex, i.uv67.zw)*0.25; // 2.0
		half4 sampleJ = tex2D(_MainTex, i.uv89.xy)*0.125;
		half4 sampleK = tex2D(_MainTex, i.uv89.zw)*0.125; // 0.25
										
		blurredColor += sampleA;
		blurredColor += sampleB;
		blurredColor += sampleC; 
		blurredColor += sampleD; 
		blurredColor += sampleE; 
		blurredColor += sampleF; 
		blurredColor += sampleG; 
		blurredColor += sampleH; 
		blurredColor += sampleI; 
		blurredColor += sampleJ; 
		blurredColor += sampleK; 
								
		blurredColor = blurredColor / 12.25;
		
		return blurredColor;
	}		
	
	half4 fragBlurWithOneThirdApply(v2fBlur i) : COLOR 
	{
		half4 blurredColor = half4 (0,0,0,0);

		half4 sampleA = tex2D(_MainTex, i.uv.xy);
		half4 sampleB = tex2D(_MainTex, i.uv01.xy);
		half4 sampleC = tex2D(_MainTex, i.uv01.zw);
		half4 sampleD = tex2D(_MainTex, i.uv23.xy);
		half4 sampleE = tex2D(_MainTex, i.uv23.zw);
		half4 sampleF = tex2D(_MainTex, i.uv45.xy);
		half4 sampleG = tex2D(_MainTex, i.uv45.zw);
		half4 sampleH = tex2D(_MainTex, i.uv67.xy);
		half4 sampleI = tex2D(_MainTex, i.uv67.zw);
		half4 sampleJ = tex2D(_MainTex, i.uv89.xy);
		half4 sampleK = tex2D(_MainTex, i.uv89.zw);
										
		blurredColor += sampleA;
		blurredColor += sampleB;
		blurredColor += sampleC; 
		blurredColor += sampleD; 
		blurredColor += sampleE; 
		blurredColor += sampleF; 
		blurredColor += sampleG; 
		blurredColor += sampleH; 
		blurredColor += sampleI; 
		blurredColor += sampleJ; 
		blurredColor += sampleK; 
								
		blurredColor = blurredColor /9;
		
		return blurredColor / 3;
	}	
	
	mrtOut frag2BlurOptPass1(v2fBlur i) 
	{
		mrtOut fragOut;
	
		fragOut.color0 = half4 (0,0,0,0);
		fragOut.color1 = half4 (0,0,0,0);

		// BLUR 1
		half4 sampleA = tex2D(_MainTex, i.uv.xy);
		half4 sampleB = tex2D(_MainTex, i.uv01.xy);
		half4 sampleC = tex2D(_MainTex, i.uv01.zw);
		half4 sampleD = tex2D(_MainTex, i.uv23.xy);
		half4 sampleE = tex2D(_MainTex, i.uv23.zw);
		half4 sampleF = tex2D(_MainTex, i.uv45.xy);
		half4 sampleG = tex2D(_MainTex, i.uv45.zw);
		half4 sampleH = tex2D(_MainTex, i.uv67.xy);
		half4 sampleI = tex2D(_MainTex, i.uv67.zw);
								
		fragOut.color0 += sampleA;
		fragOut.color0 += sampleB;
		fragOut.color0 += sampleC; 
		fragOut.color0 += sampleD; 
		fragOut.color0 += sampleE; 
		fragOut.color0 += sampleF; 
		fragOut.color0 += sampleG; 
		fragOut.color0 += sampleH; 
		fragOut.color0 += sampleI; 
		fragOut.color0 /= 9;
		
		// BLUR 2
		sampleA = tex2D(_MainTex, i.uv.xy);
		sampleB = tex2D(_MainTex, i.uv.xy + _Offsets2.xy*1.0f);
		sampleC = tex2D(_MainTex, i.uv.xy + _Offsets2.xy*2.0f);
		sampleD = tex2D(_MainTex, i.uv.xy + _Offsets2.xy*3.0f);
		sampleE = tex2D(_MainTex, i.uv.xy + _Offsets2.xy*4.0f);
		sampleF = tex2D(_MainTex, i.uv.xy + _Offsets2.xy*5.0f);
		sampleG = tex2D(_MainTex, i.uv.xy + _Offsets2.xy*6.0f);
		sampleH = tex2D(_MainTex, i.uv.xy + _Offsets2.xy*7.0f);
		sampleI = tex2D(_MainTex, i.uv.xy + _Offsets2.xy*8.0f);
								
		fragOut.color1 += sampleA;
		fragOut.color1 += sampleB;
		fragOut.color1 += sampleC; 
		fragOut.color1 += sampleD; 
		fragOut.color1 += sampleE; 
		fragOut.color1 += sampleF; 
		fragOut.color1 += sampleG; 
		fragOut.color1 += sampleH; 
		fragOut.color1 += sampleI; 
		fragOut.color1 /= 9;
		
		fragOut.color1 += fragOut.color0;
		
		return fragOut;
	}	
	
	half4 frag2BlurOptPass2(v2fBlur i) : COLOR 
	{
		mrtOut fragOut;
	
		fragOut.color0 = half4 (0,0,0,0);
		fragOut.color1 = half4 (0,0,0,0);

		// BLUR 1
		half4 sampleA = tex2D(_MainTex, i.uv.xy);
		half4 sampleB = tex2D(_MainTex, i.uv01.xy);
		half4 sampleC = tex2D(_MainTex, i.uv01.zw);
		half4 sampleD = tex2D(_MainTex, i.uv23.xy);
		half4 sampleE = tex2D(_MainTex, i.uv23.zw);
		half4 sampleF = tex2D(_MainTex, i.uv45.xy);
		half4 sampleG = tex2D(_MainTex, i.uv45.zw);
		half4 sampleH = tex2D(_MainTex, i.uv67.xy);
		half4 sampleI = tex2D(_MainTex, i.uv67.zw);
								
		fragOut.color0 += sampleA;
		fragOut.color0 += sampleB;
		fragOut.color0 += sampleC; 
		fragOut.color0 += sampleD; 
		fragOut.color0 += sampleE; 
		fragOut.color0 += sampleF; 
		fragOut.color0 += sampleG; 
		fragOut.color0 += sampleH; 
		fragOut.color0 += sampleI; 
		fragOut.color0 /= 9.0f;
		
		// BLUR 2
		sampleA = tex2D(_MainTex2, i.uv.xy);
		sampleB = tex2D(_MainTex2, i.uv.xy + _Offsets2.xy*1.0f);
		sampleC = tex2D(_MainTex2, i.uv.xy + _Offsets2.xy*2.0f);
		sampleD = tex2D(_MainTex2, i.uv.xy + _Offsets2.xy*3.0f);
		sampleE = tex2D(_MainTex2, i.uv.xy + _Offsets2.xy*4.0f);
		sampleF = tex2D(_MainTex2, i.uv.xy + _Offsets2.xy*5.0f);
		sampleG = tex2D(_MainTex2, i.uv.xy + _Offsets2.xy*6.0f);
		sampleH = tex2D(_MainTex2, i.uv.xy + _Offsets2.xy*7.0f);
		sampleI = tex2D(_MainTex2, i.uv.xy + _Offsets2.xy*8.0f);
								
		fragOut.color1 += sampleA;
		fragOut.color1 += sampleB;
		fragOut.color1 += sampleC; 
		fragOut.color1 += sampleD; 
		fragOut.color1 += sampleE; 
		fragOut.color1 += sampleF; 
		fragOut.color1 += sampleG; 
		fragOut.color1 += sampleH; 
		fragOut.color1 += sampleI; 
		fragOut.color1 /= 9.0f;
		
		return 0.5f * (fragOut.color0 + fragOut.color1);
	}	

	// fragBlur2Gauss is mostly interested in the alpha channel and hence
	// uses gaussian for smoother foreground coc's
	
	half4 fragBlurForFgCoc (v2fBlur i) : COLOR 
	{
		half4 blurredColor = half4 (0,0,0,0);

		half4 sampleA = tex2D(_MainTex, i.uv.xy);
		half4 sampleB = tex2D(_MainTex, i.uv01.xy);
		half4 sampleC = tex2D(_MainTex, i.uv01.zw);
		half4 sampleD = tex2D(_MainTex, i.uv23.xy);
		half4 sampleE = tex2D(_MainTex, i.uv23.zw);
		half4 sampleF = tex2D(_MainTex, i.uv45.xy);
		half4 sampleG = tex2D(_MainTex, i.uv45.zw);
						
		blurredColor += sampleA*2;
		blurredColor += sampleB;
		blurredColor += sampleC; 
		blurredColor += sampleD*0.5; 
		blurredColor += sampleE*0.5; 
		blurredColor += sampleF*0.25; 
		blurredColor += sampleG*0.25; 

		blurredColor /= 5.5;
				
		//half4 maxedColor = max(sampleA, sampleB);
		//maxedColor = max(maxedColor, sampleC);
		//blurredColor.a = saturate(blurredColor.a * 4.0f);
		
		// to do ot not to do
		blurredColor.a = max(sampleA.a, blurredColor.a);
		
		return blurredColor;
	}	

	half4 frag4TapMaxDownsample (v2f i) : COLOR 
	{
		half4 tapA =  tex2D(_MainTex, i.uv1.xy + _MainTex_TexelSize);
		half4 tapB =  tex2D(_MainTex, i.uv1.xy - _MainTex_TexelSize);
		half4 tapC =  tex2D(_MainTex, i.uv1.xy + _MainTex_TexelSize * half2(1,-1));
		half4 tapD =  tex2D(_MainTex, i.uv1.xy - _MainTex_TexelSize * half2(1,-1));

		return max( max(tapA,tapB), max(tapC,tapD) );
	}	
	
	float4 fragCombine3Taps(v2f i) : COLOR 
	{
		half4 tapA = tex2D(_TapLowA, i.uv1.xy);
		half4 tapB = tex2D(_TapLowB, i.uv1.xy);
		half4 tapC = tex2D(_TapLowC, i.uv1.xy);

		return (tapA + tapB + tapC) / 3.0;
	}	
	
	float4 fragApply (v2fDofApply i) : COLOR 
	{		
		float4 tapHigh = tex2D (_MainTex, i.uv.xy);
		
		#if SHADER_API_D3D9
		if (_MainTex_TexelSize.y < 0)
			i.uv.xy = i.uv.xy * half2(1,-1)+half2(0,1);
		#endif
		
		float4 tapLow = tex2D (_TapLowA, i.uv.xy); 
		//return tapLow / tapLow.a;
		
		tapHigh = lerp (tapHigh, tapLow, saturate(tapHigh.a));
		
		// return tapHigh.aaaa;
		return tapHigh / tapHigh.a; 
	}	
	
	half4 fragApplyDebug (v2fDofApply i) : COLOR 
	{		
		float4 tapHigh = tex2D (_MainTex, i.uv.xy);
		
		#if SHADER_API_D3D9
		if (_MainTex_TexelSize.y < 0)
			i.uv.xy = i.uv.xy * half2(1,-1)+half2(0,1);
		#endif
		
		float4 tapLow = tex2D (_TapLowA, i.uv.xy); 
		//return tapLow / tapLow.a;
		
		float coc = tapHigh.a;
		tapHigh = lerp (tapHigh, tapLow, saturate(tapHigh.a));
		
		// return tapHigh.aaaa;
		return lerp(tapHigh / tapHigh.a, half4(0,1,0,0), saturate(tapHigh.a*0.65)); 
	}		
		
	float4 fragCaptureBackgroundCoc (v2f i) : COLOR 
	{	
		float4 color = tex2D (_MainTex, i.uv1.xy);
		color.a = 0.0;
		
		half4 lowTap = tex2D(_TapLowA, i.uv1.xy);
		
		float d = tex2D (_CameraDepthTexture, i.uv1.xy).x;
		d = Linear01Depth (d);
		
		float focalDistance01 = _CurveParams.w + _CurveParams.z;
		
		if (d > focalDistance01) 
			color.a = (d - focalDistance01);
	
		color.a = saturate (0.00001 + color.a * _CurveParams.y);	
		
		// for foreground COC, let's actually scale COC to have nicer overlaps		
		color.a = max(lowTap.a + saturate(lowTap.a-0.65)*5.0*saturate(lowTap.a-0.65)*5.0, color.a);
		color.rgb *= color.a;
		
		return color;
	} 
	
	half4 fragCaptureForegroundCoc (v2f i) : COLOR 
	{		
		half4 color = tex2D (_MainTex, i.uv1.xy);
		color.a = 0.0;

		#if SHADER_API_D3D9
		if (_MainTex_TexelSize.y < 0)
			i.uv1.xy = i.uv1.xy * half2(1,-1)+half2(0,1);
		#endif

		float d = tex2D (_CameraDepthTexture, i.uv1.xy);
		d = Linear01Depth (d);	
		
		half focalDistance01 = (_CurveParams.w - _CurveParams.z);	
		
		if (d < focalDistance01) 
			color.a = (focalDistance01 - d);
		
		color.a = saturate (0.00005 + color.a * _CurveParams.x);	
		
		//color.a *= 1.5;
		
		return color;	
	}	
	
	half4 fragReturnMainTex (v2f i) : COLOR 
	{	
		return tex2D(_MainTex, i.uv1.xy);
	} 	
	
	// not being used atm
	
	half4 fragCaptureCenterDepth (v2f i) : COLOR 
	{
		return 0;
	}	
	
	// used for simple one one blend
	
	half4 fragAdd (v2f i) : COLOR {	
		half4 from = tex2D( _MainTex, i.uv1.xy );
		return from;
	}
		
	ENDCG
	
Subshader {
 
 // pass 0
 
 Pass {
	  ZTest Always Cull Off ZWrite Off
	  ColorMask RGB
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vertDofApply
      #pragma fragment fragApply
      
      ENDCG
  	}

 // pass 1
 
 Pass 
 {
	  ZTest Always Cull Off ZWrite Off
	  ColorMask RGB
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vertDofApply
      #pragma fragment fragApplyDebug

      ENDCG
  	}

 // pass 2

 Pass {
	  ZTest Always Cull Off ZWrite Off
	  ColorMask RGB
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vertDofApply
      #pragma fragment fragApplyDebug

      ENDCG
  	}
  	
  	
 
 // pass 3
 
 Pass 
 {
	  ZTest Always Cull Off ZWrite Off
	  // ColorMask A
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vert
      #pragma fragment fragCaptureBackgroundCoc

      ENDCG
  	}  
  	 	
	
 // pass 4

 Pass 
 {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      
	  Blend One One

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vertBlur
      #pragma fragment fragBlurWithOneThirdApply
      
      ENDCG
  	}  	

 // pass 5
  
 Pass 
 {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vert
      #pragma fragment fragCaptureForegroundCoc

      ENDCG
  	} 

 // pass 6
 
 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vertBlurPlusMinus
      #pragma fragment fragBlur9TapGauss

      ENDCG
  	} 

 // pass 7
 
 Pass { 
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vert
      #pragma fragment frag4TapMaxDownsample

      ENDCG
  	} 

 // pass 8
 
 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Blend One One
	  ColorMask RGB
  	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vert
      #pragma fragment fragAdd

      ENDCG
  	} 
  	
 // pass 9 
 // TODO: make max blend work
 
 Pass 
 {
	  ZTest Always Cull Off ZWrite Off
	  ColorMask A
	  Blend One One
	  Fog { Mode off }       

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vert
      #pragma fragment fragReturnMainTex
      ENDCG
  	} 
  	
 // pass 10
 
 Pass 
 {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vertBlur
      #pragma fragment fragBlur9Tap

      ENDCG
  	}   	
  	
 // pass 11
 
 Pass 
 {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vertBlurPlusMinus
      #pragma fragment fragBlurForFgCoc

      ENDCG
  	}   	
  
 // pass 12
 // FREEEEEE TO USE NOW
 
 Pass 
 {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vert
      #pragma fragment fragCaptureCenterDepth

      ENDCG
 }   	
 
 // pass 13
 
 Pass 
 {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vertBlur
      #pragma fragment frag2BlurOptPass1

      ENDCG
  	}   
  	
 // pass 14
 
 Pass 
 {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma glsl
      #pragma target 3.0
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vertBlur
      #pragma fragment frag2BlurOptPass2

      ENDCG
  	}    	
}
  
Fallback off

}