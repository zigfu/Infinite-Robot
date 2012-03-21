using UnityEngine;
using System.Collections;

public class DestroyOnCollide : MonoBehaviour {

	void OnCollisionEnter(Collision collision) 
	{
		print("collision detected: destroy!");
	    //Destroy (gameObject);
		renderer.material.color = Color.blue;
		Rigidbody other = gameObject.GetComponent<Rigidbody>();
		other.isKinematic = false;
		
		EnemyShoot script = (EnemyShoot)GetComponent("EnemyShoot");
		script.SetActive(false);
	}
}
