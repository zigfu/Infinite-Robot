using UnityEngine;
using System.Collections;

public class LeftHandKeyboardControl : MonoBehaviour {

	private Vector3 startPos;
	
	private float currX;
	private float currY;
	
	public GameObject isectPlane;
	
	void Start () {
		startPos = transform.localPosition;
		currX = 0.0f;
		currY = 0.0f;
	}
	
	// Update is called once per frame
	public float horizontalSpeed = 0.1f;
    public float verticalSpeed = 0.1f;
	public float minX = -1f;
	public float minY = -1f;
	public float maxX = 1f;
	public float maxY = 1f;
	
    void Update() {
		
		Ray mouseRay = Camera.main.ScreenPointToRay(Input.mousePosition);
        Plane plane = new Plane(mouseRay.direction, transform.parent.position + mouseRay.direction*2);
        float distance = 0.0f;
        plane.Raycast(mouseRay, out distance);

        if(distance > 0.0){
            Vector3 hitPoint  = mouseRay.GetPoint(distance);
            // do something with hitPoint....
			//print("hit");
			transform.position = hitPoint;
        }
    }
}
