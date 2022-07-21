import Head from "next/head"
import Image from "next/image"
import styles from "../styles/Home.module.css"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import { useAccount } from "wagmi"
import MintButton from "../components/MintButton"

export default function Home() {
    const { address } = useAccount()

    return (
        <div className={styles.container}>
            <Head>
                <title>Mint NFT</title>
                <meta name="description" content="" />
                <link rel="icon" href="/favicon.ico" />
            </Head>

            <main className={styles.main}>
                <h1 className={styles.title}>Mint NFT</h1>

                <p className={styles.description}>
                    <br />
                    <div style={{display: "flex", justifyContent: "center"}}>
                        <ConnectButton showBalance={false} />
                    </div>
                    {address && (
                        <>
                            <MintButton />

                            <p>
                                need test matic for gas? ask from this{" "}
                                <a
                                    href="https://faucet.polygon.technology"
                                    target="_new"
                                    style={{ color: "#0070f3" }}
                                >
                                    faucet
                                </a>
                            </p>
                        </>
                    )}
                </p>
            </main>

            <footer className={styles.footer}>
                <a
                    href="https://vercel.com?utm_source=create-next-app&utm_medium=default-template&utm_campaign=create-next-app"
                    target="_blank"
                    rel="noopener noreferrer"
                >
                    Powered by{" "}
                    <span className={styles.logo}>
                        <Image src="/vercel.svg" alt="Vercel Logo" width={72} height={16} />
                    </span>
                </a>
            </footer>
        </div>
    )
}
