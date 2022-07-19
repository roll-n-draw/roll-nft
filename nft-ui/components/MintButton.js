export default function MintButton() {
    const handleMintClick = async () => {
        const imageBytes = await fetch("/api/image")
        
        alert("Under Construction!")
    }
    return (
        <button style={{ marginTop: "50px" }} className="button-3" onClick={handleMintClick}>
            M I N T
        </button>
    );
}
