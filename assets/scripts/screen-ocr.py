import argparse
from pathlib import Path

import rapidocr
from rapidocr import EngineType, ModelType, OCRVersion, RapidOCR


def main():
    parser = argparse.ArgumentParser(
        description="Recognize screen text on CPU"
    )
    parser.add_argument("image", type=Path)
    args = parser.parse_args()

    # Nixpkgs bundles these weights. Explicit paths avoid runtime downloads.
    models = Path(rapidocr.__file__).resolve().parent / "models"
    engine = RapidOCR(params={
        "Global.log_level": "warning",
        "Det.engine_type": EngineType.ONNXRUNTIME,
        "Det.ocr_version": OCRVersion.PPOCRV6,
        "Det.model_type": ModelType.SMALL,
        "Det.model_path": str(models / "PP-OCRv6_det_small.onnx"),
        # Do not inflate narrow selections to a 736-pixel minimum height.
        "Det.limit_type": "max",
        "Det.limit_side_len": 1920,
        "Cls.engine_type": EngineType.ONNXRUNTIME,
        "Cls.model_path": str(models / "ch_ppocr_mobile_v2.0_cls_mobile.onnx"),
        "Rec.engine_type": EngineType.ONNXRUNTIME,
        "Rec.ocr_version": OCRVersion.PPOCRV6,
        "Rec.model_type": ModelType.SMALL,
        "Rec.model_path": str(models / "PP-OCRv6_rec_small.onnx"),
        # Never select a GPU provider, including on the hybrid-GPU laptop.
        "EngineConfig.onnxruntime.use_cuda": False,
        "EngineConfig.onnxruntime.use_dml": False,
        "EngineConfig.onnxruntime.use_cann": False,
        "EngineConfig.onnxruntime.use_coreml": False,
        "EngineConfig.onnxruntime.intra_op_num_threads": 2,
        "EngineConfig.onnxruntime.inter_op_num_threads": 1,
    })
    result = engine(args.image)
    text = "\n".join(result.txts or ())
    if text:
        print(text)


if __name__ == "__main__":
    main()
