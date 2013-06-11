attribute vec4 Position; 
attribute vec4 SourceColor; 

varying vec4 DestinationColor;
varying float LightIntensity;
uniform mat4 Projection;
uniform mat4 Modelview;

void main(void)
{ 
    DestinationColor = SourceColor; 
    gl_Position = Projection * Modelview * Position;
    vec3 lightDirection = vec3(0.4,0.6,-0.8);
    vec3 newNormal = (Modelview * Position).xyz;
    LightIntensity = max(0.0, dot(newNormal, lightDirection));
}