using UnityEngine;
using System.Collections;

public class MouseCharacterControl : MonoBehaviour {
	
	private Vector3 startPos;
	
	public float speed = 0.1f;

	// Use this for initialization
	void Start () {
		startPos = transform.localPosition;
	
	}
	
	// Update is called once per frame
    void Update() {
        float w = Input.GetKey(KeyCode.W) ? speed : 0.0f;
        float a = Input.GetKey(KeyCode.A) ? -speed : 0.0f;
		float s = Input.GetKey(KeyCode.S) ? -speed : 0.0f;
		float d = Input.GetKey(KeyCode.D) ? speed : 0.0f;

		transform.Translate(new Vector3(w+s,a+d,0.0f));
	}
}
