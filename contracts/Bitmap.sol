// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct XY {
    int256 x;
    int256 y;
}

struct RGB {
    bytes1 red;
    bytes1 green;
    bytes1 blue;
}

struct Bitmap {
    bytes data;
    uint256 lineSize;
}

library BitmapLib {
    uint256 constant headerSize = 54;
    uint256 constant pixelSize = 3;

    function init(Bitmap memory bitmap, XY memory size) internal pure {
        // 32bitの場合は1ピクセルあたりRGBAの4byteなので必ず1ラインの数は4の倍数になり問題ない。しかし24bit bitmapの場合1ピクセルあたりRGBで3byteになる。よって1ラインあたり4の倍数で割り切れない。
        // そのために下記のような処理をする
        // 1 2 3 4 5 6 7 8 9 10 11 12
        // b g r b g r b g r <= 9バイトなので4の倍数にならない
        // b g r b g r b g r 00 00 00 <= 00で埋めて12byteにすることで4の倍数にする => padding処理
        uint256 linePadding = (uint256(size.x) * pixelSize) % 4 == 0
            ? 0
            : 4 - ((uint256(size.x) * pixelSize) % 4);
        bitmap.lineSize = uint256(size.x) * pixelSize + linePadding;
        uint256 bodySize = bitmap.lineSize * uint256(size.y);
        uint256 fileSize = headerSize + bodySize;
        bitmap.data = new bytes(fileSize);

        bitmap.data[0] = 0x42; // B
        bitmap.data[1] = 0x4d; // M
        setUint32(bitmap, 2, uint32(fileSize)); // ファイルサイズ
        // 6: 予約領域: 0
        // 8: 予約領域: 0
        setUint32(bitmap, 10, uint32(headerSize)); // 画像データまでのoffset
        setUint32(bitmap, 14, 40); // 情報ヘッダのサイズ
        setUint32(bitmap, 18, uint32(int32(size.x))); // 画像の幅
        setUint32(bitmap, 22, uint32(int32(size.y))); // 画像の高さ
        setUint16(bitmap, 26, 1); // プレーン数
        setUint16(bitmap, 28, uint16(pixelSize * 8)); // 色ビット数
        // 30: 圧縮形式: 0
        setUint32(bitmap, 34, uint32(bodySize)); // 画像データサイズ
    }

    // ビットマップにピクセルデータを書き込む
    // setPixel(bitmap, XY(1, 1), RGB(1, 1, 0))
    // 000 000 000    000 000 000
    // 000 000 000 => 000 110 000
    // 000 000 000    000 000 000
    function setPixel(
        Bitmap memory bitmap,
        XY memory position,
        RGB memory pixel
    ) internal pure {
        uint256 index = headerSize +
            uint256(position.y) *
            bitmap.lineSize +
            uint256(position.x) *
            pixelSize;
        bitmap.data[index] = pixel.blue;
        bitmap.data[index + 1] = pixel.green;
        bitmap.data[index + 2] = pixel.red;
    }

    // ビットマップに画像データを書き込む
    function setBody(Bitmap memory bitmap, bytes memory body) internal pure {
        uint256 bodyLength = body.length;
        require(bitmap.data.length == headerSize + bodyLength);
        for (uint256 i = 0; i < bodyLength; i++) {
            bitmap.data[headerSize + i] = body[i];
        }
    }

    // 4byte用 bitmapにoffsetの位置からvalueを書き込む
    function setUint32(
        Bitmap memory bitmap,
        uint256 offset,
        uint32 value
    ) private pure {
        for (uint256 i = 0; i < 4; i++) {
            bitmap.data[offset + i] = bytes1(uint8(value / (2**(8 * i))));
        }
    }

    // 2byte用 bitmapにoffsetの位置からvalueを書き込む
    function setUint16(
        Bitmap memory bitmap,
        uint256 offset,
        uint16 value
    ) private pure {
        for (uint256 i = 0; i < 2; i++) {
            bitmap.data[offset + i] = bytes1(uint8(value / (2**(8 * i))));
        }
    }
}
