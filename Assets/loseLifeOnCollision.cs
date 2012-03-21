using UnityEngine;
using System.Collections;

public class loseLifeOnCollision : MonoBehaviour {
	GameObject scoreKeeper;
	// Use this for initialization
	void Start () {
		scoreKeeper = GameObject.Find("scoreKeeper");
	}
	
	// Update is called once per frame
	void Update () {
	
	}
	void OnCollisionEnter(Collision other)
	{
	if (other.gameObject.tag == "damaging")
	{
		Destroy(other.gameObject);
		if (scoreKeeper.GetComponent<scoreKeeper>().hp > 0)
		{
			scoreKeeper.GetComponent<scoreKeeper>().TakeDamage(10);
		}	
		if (scoreKeeper.GetComponent<scoreKeeper>().hp == 0)
		{
			GameObject clone = (GameObject)Instantiate(explosionObject,transform.position,Quaternion.identity);
			clone.transform.parent = this.transform;
			childExplosion = clone;
		
			StartCoroutine("DestroyAfter");
		}
	}
	}
	
	
		public GameObject explosionObject;
	public float secondsToLive = 0.1f;
	private GameObject childExplosion;
	
	
	
	IEnumerator DestroyAfter()
	{
		yield return new WaitForSeconds(secondsToLive);
		childExplosion.transform.parent = null;
		ParticleEmitter pe = (ParticleEmitter)childExplosion.GetComponent("ParticleEmitter");
		pe.emit = false;
		
		yield return new WaitForSeconds(2);
		Destroy(childExplosion);
		//Destroy(gameObject);
		//scoreKeeper.GetComponent<scoreKeeper>().AddScore(100);
		print("enemy self-destruct");
	}
	
}
