shader_type spatial;
render_mode unshaded;
render_mode cull_back;
render_mode depth_draw_never;

#define USE_PERFORMANCE_MODE
#define USE_BOX_BORDER
//#define RENDER_REVERSE


uniform float _totalBrightness;

uniform int _maxSteps;
uniform float _stepSize;
uniform vec3 _rdRotation;

uniform vec3 _lightDir;
uniform float _maxLightDistance;
uniform float _transmissionThreshhold;
uniform float _lightStepSize;
uniform float _lightDensityScale;
uniform int _maxLightSteps;

uniform vec3 _volumeOffset;
uniform vec3 _volumeRotation;
uniform vec3 _volumeScale;

uniform float _densityScale;
uniform float _darknessThreshhold;
uniform float _transmittance;
uniform float _lightAbsorb;

uniform float _epsilon;

uniform sampler2D _gradientTex;
uniform vec4 _gradientTex_ST;
uniform sampler3D _volumeTex; 

varying	vec3 ro;
varying	vec3 hitPos;
varying	vec3 normal;
varying vec3 worldSpaceCameraPos;

mat2 rot(float angle){
  float s = sin(angle);
  float c = cos(angle);
  return mat2(vec2(c, -s), vec2(s, c));
}

void rotateX(inout vec3 p, float angle){
  p.xy = p.xy * rot(angle);
}

void rotateY(inout vec3 p, float angle){
  p.xz = p.xz * rot(angle);
}

void rotateZ(inout vec3 p, float angle){
  p.yz = p.yz * rot(angle);
} 

void rotate(inout vec3 p, vec3 euler){
  rotateX(p, euler.x);
  rotateY(p, euler.y);
  rotateZ(p, euler.z);
}
 
float getScene(vec3 p){
    p /= _volumeScale;
    rotate(p, radians(_volumeRotation));
	p += 0.5;
	return texture(_volumeTex, p + _volumeOffset).r;
}

bool outOfBounds(vec3 currentPos) {
 
      #if defined(USE_BOX_BORDER)
		return (max(abs(currentPos.x), max(abs(currentPos.y), abs(currentPos.z))) > 0.5f + _epsilon);
	  #else
		return false;
     #endif
}

bool outOfBoundsLight(vec3 lightPos) {
	 #if defined(USE_BOX_BORDER)
		return (max(abs(lightPos.x), max(abs(lightPos.y), abs(lightPos.z))) > 0.5f + _maxLightDistance);
	  #else
		return false;
     #endif
}

vec4 raymarch(vec3 rayOrigin, vec3 rayDirection) {

    float density = 0.;
    float transmission = 0.;
    float lightAccumulation = 0.;
    float finalLight = 0.;
    vec3 lightingResult = vec3(0);
	
	float transmittance = _transmittance;
	
    vec3 marchVector = rayDirection * _stepSize;

    vec3 lightVector = -normalize(_lightDir) * _lightStepSize;
    vec3 currentPos = rayOrigin.xyz;

    float densityFactor = _densityScale * 0.001;

    for (int i = 0; i < _maxSteps; i++) {
        currentPos += marchVector;
		
		if (outOfBounds(currentPos)) continue;
	
        float sampledDensity = getScene(currentPos);
        density += sampledDensity * densityFactor; 

        #if defined(USE_PERFORMANCE_MODE)
            lightAccumulation += sampledDensity * _lightDensityScale;
        #else
            vec3 lightRo = currentPos; 
            for(int j = 0; j < _maxLightSteps; j++){
                lightRo += lightVector;
				
				if(transmittance < _transmissionThreshhold || outOfBoundsLight(lightRo)) break;
				
                float lightDensity = getScene(lightRo);
                lightAccumulation += lightDensity * _lightDensityScale;
            }
        #endif

        float lightTransmission = exp(-lightAccumulation);
        float shadow = _darknessThreshhold + lightTransmission * (1.0 - _darknessThreshhold);
        finalLight += density * transmittance * shadow;
        transmittance *= exp(-density * _lightAbsorb);

    } 
    transmission = exp(-density);
    lightingResult = vec3(finalLight, transmission, transmittance);

	vec2 uv = vec2(finalLight * 2., finalLight) * _gradientTex_ST.xy + _gradientTex_ST.zw;
	uv.x = mix(0., uv.x, transmission);
	uv.y = mix(0., uv.y, transmission);
    vec4 gradientColor = texture(_gradientTex, uv); 
	
	vec4 resultColor = gradientColor * finalLight;
	resultColor.a = (1. - transmittance);

    return resultColor;
}

void vertex() {
  hitPos = VERTEX;
  ro = (inverse(MODELVIEW_MATRIX) * vec4(0, 0, 0, 1)).xyz;
  worldSpaceCameraPos = CAMERA_POSITION_WORLD;  
}

void fragment() {
	#if defined(RENDER_REVERSE)
		vec3 _ro = ro;
		vec3 rd = normalize(hitPos - ro.xyz);
		_ro += rd * _stepSize * float(_maxSteps);
		rd = - rd;
		vec4 col = raymarch(_ro, rd);
	#else
		vec3 rd = normalize(hitPos - ro.xyz);
		vec4 col = raymarch(ro, rd);
	#endif

		ALBEDO.xyz = clamp(col.xyz * _totalBrightness, 0., 1.) ;
		ALPHA = col.w;
}
