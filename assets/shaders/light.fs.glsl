#version 330

// Input vertex attributes (from vertex shader)
in vec3 fragPosition;
in vec2 fragTexCoord;
//in vec4 fragColor;
in vec3 fragNormal;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

// NOTE: Add here your custom variables

#define     MAX_LIGHTS              4
#define     LIGHT_DIRECTIONAL       0
#define     LIGHT_POINT             1

struct Light {
    vec3 position;
    vec3 direction;
    vec4 color;
};

// Input lighting values
uniform Light flashLight;
uniform vec4 ambient;
uniform vec3 viewPos;

void main()
{
    // Texel color fetching from texture sampler
    vec4 texelColor = texture(texture0, fragTexCoord);
    vec3 lightDot = vec3(0.0);
    vec3 normal = normalize(fragNormal);
    vec3 viewD = normalize(viewPos - fragPosition);
    float lightDistance = (flashLight.position - fragPosition).length;

    vec3 light = normalize(flashLight.position - fragPosition);

    float NdotL = max(dot(normal, light), 0.0);
    lightDot += flashLight.color.rgb * NdotL;

    finalColor = texelColor * (colDiffuse * vec4(lightDot, 1.0));
    finalColor += texelColor * (ambient / 10.0) * colDiffuse;

    // Gamma correction
    finalColor = pow(finalColor, vec4(1.0 / 2.2));
}
